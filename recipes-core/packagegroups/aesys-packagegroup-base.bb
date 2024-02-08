DESCRIPTION = "Aesys HW base packagegroup"
SUMMARY = "Aesys packagegroup - base"

inherit packagegroup

# Add basic utils
RDEPENDS:${PN} = "util-linux minicom nano"

