SUMMARY = "Aesys INITRAMFS INIT recipe"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} += "bash"

SRC_URI = " \
    file://init-aesys.sh \
    file://overlayroot-commit.sh \
    file://xdelta-apply.sh \
    file://SW_code_signer.ECC_PKI_AESYS.publickey.pem \
"

FILES:${PN} += " \
    /init \
    /overlayroot-commit.sh \
    /xdelta-apply.sh \
    /securefs.publickey.pem \
"

do_install() {
    install -m 0755 ${WORKDIR}/init-aesys.sh ${D}/init
    install -m 0555 ${WORKDIR}/overlayroot-commit.sh ${D}/overlayroot-commit.sh
    install -m 0555 ${WORKDIR}/xdelta-apply.sh ${D}/xdelta-apply.sh
    install -m 0444 ${WORKDIR}/SW_code_signer.ECC_PKI_AESYS.publickey.pem ${D}/securefs.publickey.pem
}

