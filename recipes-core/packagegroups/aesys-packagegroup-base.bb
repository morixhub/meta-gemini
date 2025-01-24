DESCRIPTION = "Aesys base packagegroup"
SUMMARY = "Aesys packagegroup - base"

inherit packagegroup

# Add basic utils
RDEPENDS:${PN}:append = " htop ethtool i2c-tools iperf3 util-linux minicom nano devmem2 libgpiod-tools spidev-test nmap tcpdump evtest memtester rsync zip unzip stress-ng avahi "

# Request by OS harderning scripts
RDEPENDS:${PN}:append = " dialog iproute2-ss tcp-wrappers rsyslog cronie "