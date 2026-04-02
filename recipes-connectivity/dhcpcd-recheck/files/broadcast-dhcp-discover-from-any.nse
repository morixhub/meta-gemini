local coroutine = require "coroutine"
local dhcp = require "dhcp"
local ipOps = require "ipOps"
local math = require "math"
local nmap = require "nmap"
local packet = require "packet"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Sends a DHCPDISCOVER to the broadcast address (255.255.255.255) using a
manually crafted raw Ethernet/IP/UDP/BOOTP/DHCP packet with source IP
0.0.0.0 and reports the results.

The script reads the response using pcap by opening a listening pcap socket
on all available ethernet interfaces that are reported up.

The script needs to be run as a privileged user, typically root.
]]

author = "Patrik Karlsson + rewritten raw-send version"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"broadcast", "safe"}

----------------------------------------------------------------------
-- PRERULE
----------------------------------------------------------------------

prerule = function()
  if not nmap.is_privileged() then
    stdnse.verbose1("not running for lack of privileges.")
    return false
  end

  if nmap.address_family() ~= "inet" then
    stdnse.debug1("is IPv4 compatible only.")
    return false
  end

  return true
end

----------------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------------

local function fail(err)
  return stdnse.format_output(false, err)
end

local commasep = {
  __tostring = function(t)
    return table.concat(t, ", ")
  end
}

-- Return all ethernet interfaces that are up
local function getInterfaces(link, up)
  if not nmap.list_interfaces then
    return nil
  end

  local interfaces, err = nmap.list_interfaces()
  local result

  if not err and interfaces then
    for _, iface in ipairs(interfaces) do
      if iface.link == link and iface.up == up then
        result = result or {}
        result[iface.device] = true
      end
    end
  end

  return result
end

-- Convert MAC address to raw 6-byte binary
-- Supports:
--   "aa:bb:cc:dd:ee:ff"
--   "aa-bb-cc-dd-ee-ff"
--   raw 6-byte string
local function mac_to_bytes(mac)
  if not mac then
    return nil
  end

  -- Already raw 6-byte binary
  if type(mac) == "string" and #mac == 6 then
    return mac
  end

  mac = tostring(mac)
  local hex = mac:gsub(":", ""):gsub("-", ""):lower()

  if #hex ~= 12 or hex:match("[^0-9a-f]") then
    return nil
  end

  local out = ""
  for i = 1, 12, 2 do
    out = out .. string.char(tonumber(hex:sub(i, i + 1), 16))
  end

  return out
end

local function ip_to_bytes(ip)
  return ipOps.ip_to_str(ip)
end

-- Internet checksum
local function checksum(data)
  if (#data % 2) ~= 0 then
    data = data .. "\0"
  end

  local sum = 0
  for i = 1, #data, 2 do
    local hi = data:byte(i)
    local lo = data:byte(i + 1)
    local word = hi * 256 + lo
    sum = sum + word

    while sum > 0xFFFF do
      sum = (sum & 0xFFFF) + (sum >> 16)
    end
  end

  return (~sum) & 0xFFFF
end

----------------------------------------------------------------------
-- PACKET BUILDERS
----------------------------------------------------------------------

local function build_eth_header(src_mac, dst_mac, ethertype)
  local dst = mac_to_bytes(dst_mac)
  local src = mac_to_bytes(src_mac)

  if not dst then
    return nil, "Invalid destination MAC: " .. tostring(dst_mac)
  end

  if not src then
    return nil, "Invalid source MAC: " .. tostring(src_mac)
  end

  return dst .. src .. string.pack(">I2", ethertype)
end

local function build_ipv4_header(src_ip, dst_ip, payload_len, proto, identification)
  local version_ihl = 0x45
  local tos = 0
  local total_length = 20 + payload_len
  local flags_frag = 0
  local ttl = 64
  local hdr_checksum = 0

  local header = string.pack(">BBI2I2I2BBI2c4c4",
    version_ihl,
    tos,
    total_length,
    identification,
    flags_frag,
    ttl,
    proto,
    hdr_checksum,
    ip_to_bytes(src_ip),
    ip_to_bytes(dst_ip)
  )

  hdr_checksum = checksum(header)

  return string.pack(">BBI2I2I2BBI2c4c4",
    version_ihl,
    tos,
    total_length,
    identification,
    flags_frag,
    ttl,
    proto,
    hdr_checksum,
    ip_to_bytes(src_ip),
    ip_to_bytes(dst_ip)
  )
end

local function build_udp_header(src_ip, dst_ip, src_port, dst_port, payload)
  local udp_len = 8 + #payload
  local udp_checksum = 0

  local udp_header = string.pack(">I2I2I2I2",
    src_port,
    dst_port,
    udp_len,
    udp_checksum
  )

  local pseudo = string.pack(">c4c4BBI2",
    ip_to_bytes(src_ip),
    ip_to_bytes(dst_ip),
    0,
    17, -- UDP
    udp_len
  )

  udp_checksum = checksum(pseudo .. udp_header .. payload)

  return string.pack(">I2I2I2I2",
    src_port,
    dst_port,
    udp_len,
    udp_checksum
  )
end

----------------------------------------------------------------------
-- PCAP LISTENER
----------------------------------------------------------------------

local function dhcp_listener(sock, timeout, xid, result)
  local condvar = nmap.condvar(result)
  sock:set_timeout(100)

  local start_time = nmap.clock_ms()

  while nmap.clock_ms() - start_time < timeout do
    local status, _, _, data = sock:pcap_receive()

    -- abort if another thread already found a response
    if #result > 0 then
      sock:close()
      condvar "signal"
      return
    end

    if status and data then
      local p = packet.Packet:new(data, #data)

      if p and p.udp_dport then
        -- DHCP payload starts after UDP header
        local payload = data:sub(p.udp_offset + 9)

        local ok, response = dhcp.dhcp_parse(payload, xid)
        if ok then
          table.insert(result, response)
          sock:close()
          condvar "signal"
          return
        end
      end
    end
  end

  sock:close()
  condvar "signal"
end

----------------------------------------------------------------------
-- RAW DHCP DISCOVER SENDER
----------------------------------------------------------------------

local function send_raw_dhcp_discover(iface_name, src_mac, dhcp_payload)
  local src_ip = "0.0.0.0"
  local dst_ip = "255.255.255.255"
  local src_port = 68
  local dst_port = 67

  local udp_header = build_udp_header(src_ip, dst_ip, src_port, dst_port, dhcp_payload)
  local ip_payload = udp_header .. dhcp_payload
  local ip_header = build_ipv4_header(src_ip, dst_ip, #ip_payload, 17, math.random(0, 0xFFFF))

  local eth_header, eth_err = build_eth_header(src_mac, "ff:ff:ff:ff:ff:ff", 0x0800)
  if not eth_header then
    return false, eth_err
  end

  local frame = eth_header .. ip_header .. ip_payload

  stdnse.debug1("[broadcast-dhcp-discover] Sending raw DHCPDISCOVER on %s", tostring(iface_name))
  stdnse.debug1("[broadcast-dhcp-discover] Source MAC: %s", tostring(src_mac))
  stdnse.debug1("[broadcast-dhcp-discover] Source IP: 0.0.0.0, Dest IP: 255.255.255.255")

  -- IMPORTANT:
  -- This requires NSE exposing dnet raw Ethernet APIs.
  if not nmap.new_dnet then
    return false, "nmap.new_dnet() is not available in this Nmap/NSE build"
  end

  local sock = nmap.new_dnet()
  if not sock then
    return false, "Failed to create raw dnet sender"
  end

  if not sock.ethernet_open then
    return false, "ethernet_open() is not available in this Nmap/NSE build"
  end

  if not sock.ethernet_send then
    return false, "ethernet_send() is not available in this Nmap/NSE build"
  end

  local ok, err = sock:ethernet_open(iface_name)
  if not ok then
    return false, "Failed to open raw ethernet on " .. tostring(iface_name) .. ": " .. tostring(err)
  end

  ok, err = sock:ethernet_send(frame)

  if sock.ethernet_close then
    sock:ethernet_close()
  end

  if not ok then
    return false, "Failed to send raw Ethernet frame: " .. tostring(err)
  end

  return true
end

----------------------------------------------------------------------
-- MAIN ACTION
----------------------------------------------------------------------

action = function()
  local timeout = stdnse.parse_timespec(stdnse.get_script_args("broadcast-dhcp-discover.timeout"))
  timeout = (timeout or 10) * 1000

  local interfaces

  -- If user specified -e, use only that interface
  if nmap.get_interface() then
    interfaces = { [nmap.get_interface()] = true }
  else
    interfaces = getInterfaces("ethernet", "up")
  end

  if not interfaces then
    return fail("Failed to retrieve interfaces (try setting one explicitly using -e)")
  end

  -- Select primary interface
  local selected_if = nmap.get_interface()
  if not selected_if then
    for ifname, _ in pairs(interfaces) do
      selected_if = ifname
      break
    end
  end

  stdnse.debug1("[broadcast-dhcp-discover] Selected interface: %s", tostring(selected_if))

  -- Find MAC address from interface list
  local mac = nil
  local all_ifaces, ierr = nmap.list_interfaces()

  if all_ifaces then
    for _, ifc in ipairs(all_ifaces) do
      if ifc.device == selected_if then
        mac = ifc.mac or ifc.address or ifc.mac_addr
        break
      end
    end
  end

  stdnse.debug1("[broadcast-dhcp-discover] MAC value: %s (len=%s)",
    tostring(mac),
    tostring(type(mac) == "string" and #mac or "n/a"))

  if not mac then
    return fail("Failed to retrieve MAC address for interface " .. tostring(selected_if))
  end

  -- Build DHCP payload
  local transaction_id = string.pack("<I4", math.random(0, 0x7FFFFFFF))
  local request_type = dhcp.request_types["DHCPDISCOVER"]
  local ip_address = ipOps.ip_to_str("0.0.0.0")

  -- BOOTP broadcast flag set
  local request_options = nil
  local overrides = { flags = 0x8000 }
  local lease_time = nil

  local status, dhcp_payload = dhcp.dhcp_build(
    request_type,
    ip_address,
    mac,
    nil,
    request_options,
    overrides,
    lease_time,
    transaction_id
  )

  if not status then
    return fail("Failed to build DHCP payload")
  end

  local threads = {}
  local result = {}
  local condvar = nmap.condvar(result)

  -- Start listener thread for each interface
  for ifname, _ in pairs(interfaces) do
    local sock = nmap.new_socket()
    sock:pcap_open(ifname, 1500, false, "ip && udp && port 68")
    local co = stdnse.new_thread(dhcp_listener, sock, timeout, transaction_id, result)
    threads[co] = true
  end

  -- Send raw Ethernet DHCPDISCOVER
  local ok, send_err = send_raw_dhcp_discover(selected_if, mac, dhcp_payload)
  if not ok then
    return fail(send_err)
  end

  -- Wait for listener threads
  repeat
    for thread in pairs(threads) do
      if coroutine.status(thread) == "dead" then
        threads[thread] = nil
      end
    end

    if next(threads) then
      condvar "wait"
    end
  until next(threads) == nil

  if not next(result) then
    return nil
  end

  local response = stdnse.output_table()

  for i, r in ipairs(result) do
    local result_table = stdnse.output_table()
    result_table["IP Offered"] = r.yiaddr_str

    for _, v in ipairs(r.options) do
      if type(v.value) == "table" then
        setmetatable(v.value, commasep)
      end
      result_table[v.name] = v.value
    end

    response[string.format("Response %d of %d", i, #result)] = result_table
  end

  return response
end