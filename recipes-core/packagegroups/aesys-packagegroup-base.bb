DESCRIPTION = "Aesys HW base packagegroup"
SUMMARY = "Aesys packagegroup - base"

inherit packagegroup

# Add basic utils
RDEPENDS:${PN} = "ethtool i2c-tools iperf3 util-linux minicom nano resizepart-script devmem2"

