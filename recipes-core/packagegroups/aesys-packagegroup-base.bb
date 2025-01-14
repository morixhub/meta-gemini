DESCRIPTION = "Aesys base packagegroup"
SUMMARY = "Aesys packagegroup - base"

inherit packagegroup

# Add basic utils
RDEPENDS:${PN} = "ethtool i2c-tools iperf3 util-linux minicom nano devmem2 libgpiod-tools spidev-test nmap tcpdump"

# Request by OS harderning scripts
RDEPENDS:${PN} = "dialog iproute2"