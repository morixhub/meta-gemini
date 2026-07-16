FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://git.yoctoproject.org/pseudo;branch=master;protocol=https \
           file://fallback-passwd \
           file://fallback-group \
           "

SRCREV = "823895ba708c63f6ae4dcbfc266210f26c02c698"
PV = "1.9.8"


# Setscene tasks which run under fakeroot must not be executed before
# pseudo-native and *all* its runtime dependencies are available in the
# sysroot.
PSEUDO_SETSCENE_DEPS = ""
PSEUDO_SETSCENE_DEPS:class-native = "sqlite3-native:do_populate_sysroot"
do_populate_sysroot_setscene[depends] += "${PSEUDO_SETSCENE_DEPS}"