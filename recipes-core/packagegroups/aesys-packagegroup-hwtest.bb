DESCRIPTION = "Aesys HW test packagegroup"
SUMMARY = "Aesys packagegroup - hwtest"

inherit packagegroup

RDEPENDS:${PN} = "ethtool i2c-tools iperf3 spidev-test"