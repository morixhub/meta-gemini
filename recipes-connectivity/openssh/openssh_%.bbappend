do_install:append(){
	
 	sed -i -e 's|^.*AllowTcpForwarding.*|AllowTcpForwarding yes|' ${D}${sysconfdir}/ssh/sshd_config
}
 	