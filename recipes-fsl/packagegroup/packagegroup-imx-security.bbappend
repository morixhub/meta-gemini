# Remove unrequested test pacakges
RDEPENDS:${PN}:remove = "${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'smw-tests', '', d)}"
