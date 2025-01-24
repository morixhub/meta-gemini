do_install:append()
{
 	sed -i -e 's|^.*AllowTcpForwarding yes.*|AllowTcpForwarding yes|' ${D}${sysconfdir}/ssh/sshd_config
}
 	