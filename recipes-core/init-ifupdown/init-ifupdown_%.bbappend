FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += "bash"

SRC_URI += " \
   file://interfaces \
   file://dhcp-timeserver \
   file://routers-down \
   file://routers-up \
   file://custom-routing \
   file://flush \
"

FILES:${PN} += " \
    ${sysconfdir}/network/interfaces \
    ${sysconfdir}/network/if-down.d/routers \
    ${sysconfdir}/network/if-down.d/flush \
    ${sysconfdir}/network/if-pre-up.d/dhcp-timeserver \
    ${sysconfdir}/network/if-pre-up.d/routers \
    ${sysconfdir}/network/if-up.d/custom-routing \
    ${sysconfdir}/network/if-post-down.d/custom-routing \
"

do_install:append(){
    
    install -d ${D}${sysconfdir}/network/
    install -d ${D}${sysconfdir}/network/interfaces.d/
    install -m 0644 ${WORKDIR}/interfaces ${D}${sysconfdir}/network/interfaces

    install -d ${D}${sysconfdir}/network/if-post-down.d/
    install -d ${D}${sysconfdir}/network/if-down.d/
    install -d ${D}${sysconfdir}/network/if-pre-up.d/
    install -d ${D}${sysconfdir}/network/if-up.d/
    install -m 755 ${WORKDIR}/dhcp-timeserver ${D}${sysconfdir}/network/if-pre-up.d/dhcp-timeserver
    install -m 755 ${WORKDIR}/routers-down ${D}${sysconfdir}/network/if-down.d/routers
    install -m 755 ${WORKDIR}/flush ${D}${sysconfdir}/network/if-down.d/flush
    install -m 755 ${WORKDIR}/routers-up ${D}${sysconfdir}/network/if-pre-up.d/routers
    install -m 755 ${WORKDIR}/custom-routing ${D}${sysconfdir}/network/if-up.d/custom-routing
    install -m 755 ${WORKDIR}/custom-routing ${D}${sysconfdir}/network/if-post-down.d/custom-routing
}