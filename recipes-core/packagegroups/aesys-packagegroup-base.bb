DESCRIPTION = "Aesys base packagegroup"
SUMMARY = "Aesys packagegroup - base"

inherit packagegroup

# Add support for /etc/network/interfaces-based networking manager
RDEPENDS:${PN}:append = " ifupdown init-ifupdown ifplugd "

# Add DHCP manager
RDEPENDS:${PN}:append = " dhcpcd dhcpcd-recheck "

# Add firewall
RDEPENDS:${PN}:append = " ufw "

# Add basic utils
RDEPENDS:${PN}:append = " e2fsprogs e2fsprogs-e2fsck e2fsprogs-mke2fs e2fsprogs-resize2fs parted dosfstools htop ethtool i2c-tools iperf3 util-linux minicom nano devmem2 libgpiod-tools spidev-test nmap tcpdump evtest memtester rsync zip unzip stress-ng strace screen "

# Request by OS harderning scripts
RDEPENDS:${PN}:append = " dialog iproute2-ss tcp-wrappers rsyslog cronie "