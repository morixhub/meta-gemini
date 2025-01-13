FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Patches
SRC_URI += " \
    file://0001-Aesys-EnterpriseOID.patch \
    file://0002-Added-Linux-6.7-Compatibility.patch \
    file://snmp.conf \
    file://snmpd.conf \
    file://conf/snmpd_aesys_base/snmpd.conf \
    file://conf/snmpd_lassy_base/snmpd.conf \
    file://conf/snmpd_v2_base/snmpd.conf \
    file://conf/tcp_any_2161/snmpd.conf \
    file://conf/tcp_any_3161/snmpd.conf \
    file://conf/tcp_any_4161/snmpd.conf \
    file://conf/tcp_localhost_161/snmpd.conf \
    file://conf/tcp_localhost_2161/snmpd.conf \
    file://conf/tcp_localhost_3161/snmpd.conf \
    file://conf/tcp_localhost_4161/snmpd.conf \
    file://conf/udp_any_161/snmpd.conf \
    file://conf/udp_any_2161/snmpd.conf \
    file://conf/udp_any_3161/snmpd.conf \
    file://conf/udp_any_4161/snmpd.conf \
    file://conf/udp_any_5161/snmpd.conf \
    file://conf/udp_any_6161/snmpd.conf \
    file://conf/udp_any_7161/snmpd.conf \
    file://conf/udp_any_8161/snmpd.conf \
    file://conf/udp_any_9161/snmpd.conf \
    file://conf/udp_any_10161/snmpd.conf \
    file://conf/udp_any_11161/snmpd.conf \
    file://conf/udp_any_12161/snmpd.conf \
    file://conf/udp_any_13161/snmpd.conf \
    file://conf/udp_any_14161/snmpd.conf \
    file://conf/udp_any_15161/snmpd.conf \
    file://conf/udp_any_16161/snmpd.conf \
    file://conf/udp_any_17161/snmpd.conf \
    file://conf/udp_any_18161/snmpd.conf \
    file://conf/udp_any_19161/snmpd.conf \
    file://conf/udp_any_20161/snmpd.conf \
    file://conf/udp_any_21161/snmpd.conf \
    file://conf/udp_any_22161/snmpd.conf \
"

FILES:${PN} += "\
    ${sysconfdir}/snmp/snmpd_aesys_base/snmpd.conf \
    ${sysconfdir}/snmp/snmpd_lassy_base/snmpd.conf \
    ${sysconfdir}/snmp/snmpd_v2_base/snmpd.conf \
    ${sysconfdir}/snmp/tcp_any_2161/snmpd.conf \
    ${sysconfdir}/snmp/tcp_any_3161/snmpd.conf \
    ${sysconfdir}/snmp/tcp_any_4161/snmpd.conf \
    ${sysconfdir}/snmp/tcp_localhost_161/snmpd.conf \
    ${sysconfdir}/snmp/tcp_localhost_2161/snmpd.conf \
    ${sysconfdir}/snmp/tcp_localhost_3161/snmpd.conf \
    ${sysconfdir}/snmp/tcp_localhost_4161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_2161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_3161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_4161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_5161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_6161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_7161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_8161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_9161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_10161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_11161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_12161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_13161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_14161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_15161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_16161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_17161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_18161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_19161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_20161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_21161/snmpd.conf \
    ${sysconfdir}/snmp/udp_any_22161/snmpd.conf \
"

do_install:append(){
    
    # Prepare  folders
    install -d ${D}${sysconfdir}/snmp/snmpd_aesys_base
    install -d ${D}${sysconfdir}/snmp/snmpd_lassy_base
    install -d ${D}${sysconfdir}/snmp/snmpd_v2_base
    install -d ${D}${sysconfdir}/snmp/tcp_any_2161
    install -d ${D}${sysconfdir}/snmp/tcp_any_3161
    install -d ${D}${sysconfdir}/snmp/tcp_any_4161
    install -d ${D}${sysconfdir}/snmp/tcp_localhost_161
    install -d ${D}${sysconfdir}/snmp/tcp_localhost_2161
    install -d ${D}${sysconfdir}/snmp/tcp_localhost_3161
    install -d ${D}${sysconfdir}/snmp/tcp_localhost_4161
    install -d ${D}${sysconfdir}/snmp/udp_any_161
    install -d ${D}${sysconfdir}/snmp/udp_any_2161
    install -d ${D}${sysconfdir}/snmp/udp_any_3161
    install -d ${D}${sysconfdir}/snmp/udp_any_4161
    install -d ${D}${sysconfdir}/snmp/udp_any_5161
    install -d ${D}${sysconfdir}/snmp/udp_any_6161
    install -d ${D}${sysconfdir}/snmp/udp_any_7161
    install -d ${D}${sysconfdir}/snmp/udp_any_8161
    install -d ${D}${sysconfdir}/snmp/udp_any_9161
    install -d ${D}${sysconfdir}/snmp/udp_any_10161
    install -d ${D}${sysconfdir}/snmp/udp_any_11161
    install -d ${D}${sysconfdir}/snmp/udp_any_12161
    install -d ${D}${sysconfdir}/snmp/udp_any_13161
    install -d ${D}${sysconfdir}/snmp/udp_any_14161
    install -d ${D}${sysconfdir}/snmp/udp_any_15161
    install -d ${D}${sysconfdir}/snmp/udp_any_16161
    install -d ${D}${sysconfdir}/snmp/udp_any_17161
    install -d ${D}${sysconfdir}/snmp/udp_any_18161
    install -d ${D}${sysconfdir}/snmp/udp_any_19161
    install -d ${D}${sysconfdir}/snmp/udp_any_20161
    install -d ${D}${sysconfdir}/snmp/udp_any_21161
    install -d ${D}${sysconfdir}/snmp/udp_any_22161

    # Install files
    install -m 644 ${WORKDIR}/conf/snmpd_aesys_base/snmpd.conf ${D}${sysconfdir}/snmp/snmpd_aesys_base/snmpd.conf
    install -m 644 ${WORKDIR}/conf/snmpd_lassy_base/snmpd.conf ${D}${sysconfdir}/snmp/snmpd_lassy_base/snmpd.conf
    install -m 644 ${WORKDIR}/conf/snmpd_v2_base/snmpd.conf ${D}${sysconfdir}/snmp/snmpd_v2_base/snmpd.conf
    install -m 644 ${WORKDIR}/conf/tcp_any_2161/snmpd.conf ${D}${sysconfdir}/snmp/tcp_any_2161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/tcp_any_3161/snmpd.conf ${D}${sysconfdir}/snmp/tcp_any_3161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/tcp_any_4161/snmpd.conf ${D}${sysconfdir}/snmp/tcp_any_4161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/tcp_localhost_161/snmpd.conf ${D}${sysconfdir}/snmp/tcp_localhost_161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/tcp_localhost_2161/snmpd.conf ${D}${sysconfdir}/snmp/tcp_localhost_2161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/tcp_localhost_3161/snmpd.conf ${D}${sysconfdir}/snmp/tcp_localhost_3161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/tcp_localhost_4161/snmpd.conf ${D}${sysconfdir}/snmp/tcp_localhost_4161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_2161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_2161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_3161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_3161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_4161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_4161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_5161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_5161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_6161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_6161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_7161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_7161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_8161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_8161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_9161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_9161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_10161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_10161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_11161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_11161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_12161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_12161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_13161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_13161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_14161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_14161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_15161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_15161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_16161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_16161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_17161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_17161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_18161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_18161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_19161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_19161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_20161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_20161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_21161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_21161/snmpd.conf
    install -m 644 ${WORKDIR}/conf/udp_any_22161/snmpd.conf ${D}${sysconfdir}/snmp/udp_any_22161/snmpd.conf
}


