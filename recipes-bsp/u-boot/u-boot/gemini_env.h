#ifndef __GEMINI_ENV_H
#define __GEMINI_ENV_H

#define GEMINI_ENVVAR_BOARD_GPIOID "gemini_board_gpioid"
#define GEMINI_ENVVAR_BOARD_ID "gemini_board_boardid"
#define GEMINI_ENVVAR_FORCED_BOARD_ID "gemini_board_forced_boardid"
#define GEMINI_ENVVAR_HWDETECT_BOOTARGS "gemini_hw_detect_bootargs"

#define GEMINI_STATIC_IPADDR "192.168.79.1"
#define GEMINI_STATIC_NETMASK "192.168.79.1"
#define GEMINI_STATIC_SERVERIP "192.168.79.253"

/*
 ATTENTION: kernel_addr_r is used by "pxe boot" for loading the kernel, but for "pxe boot" FIT images are treated
 exactly as kernel images, so kernel_addr_r must take FIT image loading into consideration, so it is clever
 to set kernel_addr_r to the same value defined for fitaddr 

 ATTENTION: normally initrd_addr is used for defining the location to load initial RAM disk image to,
 but also ramdisk_addr_r must be defined (and have the same value) since the latter is requested by
 command "pxe boot".
 */

 #define GEMINI_ENV \
    "scsidev=0\0" \
    "scsipart=1\0" \
    "bootargs=\0" \
    "bootargs_extra=vt.global_cursor_default=0 vt.cur_default=1 console=tty0 console=ttyS0,115200 consoleblank=0\0" \
    "pxeuuid="GEMINI_PXE_UUID"\0" \
    "bootcmd=run bsp_bootcmd\0" \
    "initrd=initram.img\0" \
    "initrd_addr=0x4000000\0" \
    "image=bzImage\0" \
    "ramdisk_addr_r=0x4000000\0" \
    "loadinitrd=echo Attempting load of initrd (${initrd})...; " \
        "load scsi ${scsidev}:${scsipart} ${initrd_addr} ${initrd}\0" \
    "db_id_a_addr=0x1000000\0" \
    "db_id_b_addr=0x1100000\0" \
    "db_id_cmp_size=0x40\0" \
    "db_swap_requested=echo Evaluating for dual-boot halves swap...; " \
        "if env exists db_attempt_switch; then " \
            "echo Detected attempt switch flag!; " \
            "true; " \
        "else " \
            "if env exists db_last_half; then " \
                "echo Last boot was not likely a success: evaluating dual-boot halves for swap eligibility...; " \
                "if load scsi ${scsidev}:$dbv_dual_data_partition ${db_id_a_addr} .sys/a.id; then " \
                    "if load scsi ${scsidev}:$dbv_dual_data_partition ${db_id_b_addr} .sys/b.id; then " \
                        "cmp.b ${db_id_a_addr} ${db_id_b_addr} ${db_id_cmp_size}; " \
                    "fi; " \
                "fi; " \
            "else " \
                "false; " \
            "fi; " \
        "fi;\0" \
    "fitaddr=0x1000000\0" \
    "fitimage=fit.img\0" \
    "kernel_addr_r=0x1000000\0" \
    "gemini_hw_detect=echo Gemini hardware detection report not available on x86, yet!; " \
        "setenv "GEMINI_ENVVAR_HWDETECT_BOOTARGS" \""GEMINI_ENVVAR_BOARD_GPIOID"=${"GEMINI_ENVVAR_BOARD_GPIOID"} "GEMINI_ENVVAR_BOARD_ID"=${"GEMINI_ENVVAR_BOARD_ID"} "GEMINI_ENVVAR_FORCED_BOARD_ID"=${"GEMINI_ENVVAR_FORCED_BOARD_ID"}\"\0" \
    "loadfit=echo Attempting load of FIT image (${fitimage})...; " \
        "load scsi ${scsidev}:${scsipart} ${fitaddr} ${fitimage}\0" \
    "fitboot=bootm ${fitaddr}#${gemini_fit_conf}\0" \
    "bsp_bootcmd=echo Running BSP bootcmd...; " \
        "run gemini_hw_detect; " \
        "run pxeboot; " \
        "scsi dev ${scsidev}; " \
        "if scsi rescan; " \
        "run scsiargs; " \
        "then " \
            "if run loadfit; " \
            "then " \
                "echo FIT image loaded successfully... booting...; " \
                "setenv bootargs ${bootargs} secure-boot; " \
                "run fitboot; " \
            "else " \
                "if run loadimage; " \
                "then " \
                    "echo Image available... continue booting...; " \
                    "run scsiboot; " \
                "else " \
                    "run pxeboot_nocheck; " \
                "fi; " \
            "fi; " \
        "fi\0" \
    "loadimage=echo Attempting load of image (${image})...; " \
        "load scsi ${scsidev}:${scsipart} ${kernel_addr_r} ${image}\0" \
    "scsiargs=echo Evaluating dual boot...; " \
        "dbv_dual=\"\" ; " \
        "dbv_dual_partitions=\"\" ; " \
        "dbv_dual_files=\"\" ; " \
        "dbv_dual_data_partition=\"\" ; " \
        "if ext4ls scsi ${scsidev}:3 ; then " \
            "dbv_dual=1 ; " \
            "dbv_dual_partitions=1 ; " \
            "dbv_dual_data_partition=3 ; " \
        "elif test -e scsi ${scsidev}:1 fit.img.a || test -e scsi ${scsidev}:1 Image.a ; then " \
            "dbv_dual=1 ; " \
            "dbv_dual_files=1 ; " \
            "dbv_dual_data_partition=2 ; " \
        "fi; " \
        "if test -n \"$dbv_dual\" ; then " \
            "if test -n \"$dbv_dual_partitions\" ; then " \
                "echo DUAL BOOT MODE (partitions) ; " \
            "else " \
                "echo DUAL BOOT MODE (files) ; " \
            "fi; " \
            "if test -n \"${db_force_single}\" ; then " \
                "echo FORCING SINGLE BOOT from dual-boot half A... ; " \
                "setenv db_active_half a ; " \
                "setenv db_last_half a ; " \
            "else " \
                "if env exists db_active_half && test ${db_active_half} = b ; then " \
                    "if run db_swap_requested; then " \
                        "echo Active dual-boot half switched (B->A) ; " \
                        "echo Dual booting from dual-boot half A... ; " \
                        "setenv db_active_half a ; " \
                        "setenv db_last_half a ; " \
                    "else " \
                        "echo Dual-boot halves were not swapped ; " \
                        "echo Dual booting from dual-boot half B... ; " \
                        "setenv db_active_half b ; " \
                        "setenv db_last_half b ; " \
                    "fi; " \
                "else " \
                    "if run db_swap_requested; then " \
                        "echo Active dual-boot half switched (A->B) ; " \
                        "echo Dual booting from dual-boot half B... ; " \
                        "setenv db_active_half b ; " \
                        "setenv db_last_half b ; " \
                    "else " \
                        "echo Dual-boot halves were not swapped ; " \
                        "echo Dual booting from dual-boot half A... ; " \
                        "setenv db_active_half a ; " \
                        "setenv db_last_half a ; " \
                    "fi; " \
                "fi; " \
            "fi; " \
            "saveenv ; " \
            "if test -n \"$dbv_dual_partitions\" && test ${db_last_half} = b ; then " \
                "setenv scsipart 2 ; " \
            "else " \
                "setenv scsipart 1 ; " \
            "fi; " \
            "if test -n \"$dbv_dual_files\" ; then " \
                "setenv image ${image}.${db_active_half} ; " \
                "setenv initrd ${initrd}.${db_active_half} ;  " \
                "setenv fitimage ${fitimage}.${db_active_half} ; " \
            "fi; " \
            "setenv dbargs db_active_half=${db_active_half} ; " \
            "if test -n \"$dbv_dual_partitions\" ; then " \
                "setenv dbargs ${dbargs} db_mode=partitions ; " \
            "else " \
                "setenv dbargs ${dbargs} db_mode=files ; " \
            "fi; " \
            "if test -n \"${db_force_single}\" ; then " \
                "setenv dbargs ${dbargs} db_force_single ; " \
            "fi; " \
        "else " \
            "echo SINGLE BOOT MODE ; " \
        "fi; " \
        "setenv scsiroot /dev/sda${scsipart} rootwait rw ; " \
        "setenv bootargs ${bootargs_extra} console=${console} root=${scsiroot} ${"GEMINI_ENVVAR_HWDETECT_BOOTARGS"} ${dbargs}\0" \
    "scsiboot=echo Booting from scsi...; " \
        "if run loadinitrd; " \
        "then " \
            "echo initrd loaded successfully... booting...; " \
            "zboot ${kernel_addr_r} - ${initrd_addr} ${filesize}; " \
        "else " \
            "echo initrd not available... booting...; " \
            "zboot ${kernel_addr_r}; " \
        "fi\0" \
    "pxeboot=echo Booting from PXE...; " \
        "if env exists pxe_disabled && itest $pxe_disabled == 1; then " \
            "echo PXE disabled (by environment); " \
        "elif test -e scsi ${scsidev}:2 .sys/pxe.disabled || test -e scsi ${scsidev}:3 .sys/pxe.disabled ; then " \
            "echo PXE disabled (by file-system); " \
        "else " \
            "setenv gemini_fit_conf $gemini_fit_conf ; " \
            "if env exists pxe_static_disabled && itest $pxe_static_disabled == 1; then " \
                "echo Static network configuration PXE disabled (by environment); " \
            "elif test -e scsi ${scsidev}:2 .sys/pxe.static.disabled || test -e scsi ${scsidev}:3 .sys/pxe.static.disabled ; then " \
                "echo Static network configuration PXE disabled (by file-system); " \
            "else " \
                "setenv ipaddr ${static_ipaddr} ; " \
                "setenv netmask ${static_netmask} ; " \
                "setenv serverip ${static_serverip} ; " \
                "echo Attempting PXE from full static configuration (ipaddr=${ipaddr}, netmask=${netmask}, serverip=${serverip})...; " \
                "if pxe get; then " \
                    "echo PXE server found: attempting boot from PXE...; " \
                    "pxe boot; " \
                    "echo Boot from PXE server failed from static configuration: attempting with DHCP and static server...; " \
                "else " \
                    "echo Cannot find PXE server from static configuration: attempting with DHCP and with static server...; " \
                "fi; " \
            "fi; " \
            "if env exists pxe_mixed_disabled && itest $pxe_mixed_disabled == 1; then " \
                "echo Mixed network configuration PXE disabled (by environment); " \
            "elif test -e scsi ${scsidev}:2 .sys/pxe.mixed.disabled || test -e scsi ${scsidev}:3 .sys/pxe.mixed.disabled ; then " \
                "echo Mixed network configuration PXE disabled (by file-system); " \
            "else " \
                "echo Attempting PXE with DHCP and static server (serverip=${static_serverip})...; " \
                "setenv autoload no ; " \
                "if dhcp; then " \
                    "setenv serverip ${static_serverip} ; " \
                    "if pxe get; then " \
                        "echo PXE server found: attempting boot from PXE...; " \
                        "pxe boot; " \
                        "echo Boot from PXE server failed: attempting with full DHCP...; " \
                    "else " \
                        "echo Cannot find PXE server: attempting with full DHCP...; " \
                    "fi; " \
                "else " \
                    "echo Cannot obtain valid DHCP lease: attempting with full DHCP...; " \
                "fi; " \
            "fi; " \
            "echo Attempting PXE from DHCP...; " \
            "setenv autoload no ; " \
            "if dhcp; then " \
                "if pxe get; then " \
                    "echo PXE server found: attempting boot from PXE...; " \
                    "pxe boot; " \
                    "echo Boot from PXE server failed: attempting other boot sources...; " \
                "else " \
                    "echo Cannot find PXE server: attempting other boot sources...; " \
                "fi; " \
            "else " \
                "echo Cannot obtain valid DHCP lease: attempting other boot sources...; " \
            "fi; " \
            "setenv gemini_fit_conf ; " \
        "fi\0" \
    "pxeboot_nocheck=echo Booting from PXE...; " \
        "setenv autoload no ; " \
        "if dhcp; then " \
            "if pxe get; then " \
                "echo PXE server found: attempting boot from PXE...; " \
                "pxe boot; " \
                "echo Boot from PXE server failed; " \
            "else " \
                "echo Cannot find PXE server: boot failed;" \
            "fi; " \
        "else " \
            "echo Cannot obtain valid DHCP lease: boot failed; " \
        "fi\0" \
    "quiet_part=yes\0" \
    "autoload=no\0" \
    "pxe_quick=yes\0" \
    "bootpretryperiod=5000\0" \
    "arptimeout=1000\0" \
    "arpretrycount=3\0" \
    "tftptimeout=2000\0" \
    "tftptimeoutcountmax=3\0" \
    "pxe_static_disabled=1\0" \
    "pxe_mixed_disabled=1\0" \
    "static_ipaddr="GEMINI_STATIC_IPADDR"\0" \
    "static_netmask="GEMINI_STATIC_NETMASK"\0" \
    "static_serverip="GEMINI_STATIC_SERVERIP"\0"

#endif