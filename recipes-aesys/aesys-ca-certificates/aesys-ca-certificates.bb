SUMMARY = "Aesys PKI CA certificates"
DESCRIPTION = "Adds the Aesys PKI CA certificates to the trusted store"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://RootCA.ECC.cert.pem \
"

FILES:${PN} += " \
    ${sysconfdir}/ssl/certs/Aesys_ID_RootCA.pem \
"

S = "${UNPACKDIR}"

do_install() {
    # Install Aesys ID RootCA certificate
    install -d ${D}${sysconfdir}/ssl/certs
    install -m 0777 ${S}/RootCA.ECC.cert.pem ${D}${sysconfdir}/ssl/certs/Aesys_ID_RootCA.pem

    # Provide hash link (required by OpenSSL for finding certificates)
    ln -s -r ${D}${sysconfdir}/ssl/certs/Aesys_ID_RootCA.pem ${D}${sysconfdir}/ssl/certs/dffb6e89.0
}