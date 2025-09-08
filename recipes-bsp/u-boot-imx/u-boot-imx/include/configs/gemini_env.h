#ifndef __GEMINI_ENV_H
#define __GEMINI_ENV_H

#define GEMINI_ENVVAR_BOARD_GPIOID "gemini_board_gpioid"
#define GEMINI_ENVVAR_BOARD_ID "gemini_board_boardid"
#define GEMINI_ENVVAR_FORCED_BOARD_ID "gemini_board_forced_boardid"
#define GEMINI_ENVVAR_HWDETECT_BOOTARGS "gemini_hw_detect_bootargs"

/*
 ATTENTION: kernel_addr_r is used by "pxe boot" for loading the kernel, but for "pxe boot" FIT images are treated
 exactly as kernel images, so kernel_addr_r must take FIT image loading into consideration, so it is clever
 to set kernel_addr_r to the same value defined for fitaddr 

 ATTENTION: normally initrd_addr is used for defining the location to load initial RAM disk image to,
 but also ramdisk_addr_r must be defined (and have the same value) since the latter is requested by
 command "pxe boot".
 */

 #define GEMINI_ENV \
    "bootargs_extra=vt.global_cursor_default=0 vt.cur_default=1 consoleblank=0 fbcon=logo-count:1 fbcon=logo-pos:center fbcon=nodefer\0" \
    "pxeuuid="GEMINI_PXE_UUID"\0" \
    "bootcmd=run bsp_bootcmd\0" \
    "initrd=initram.img\0" \
    "initrd_addr=0x43800000\0" \
    "ramdisk_addr_r=0x43800000\0" \
    "loadinitrd=echo Attempting load of initrd (${initrd})...; " \
        "ext4load mmc ${mmcdev}:${mmcpart} ${initrd_addr} ${initrd}\0" \
    "db_id_a_addr=0x47000000\0" \
    "db_id_b_addr=0x47010000\0" \
    "db_id_cmp_size=0x40\0" \
    "db_swap_requested=echo Evaluating for dual-boot halves swap...; " \
        "if env exists db_attempt_switch; then " \
            "echo Detected attempt switch flag!; " \
            "true; " \
        "else " \
            "if env exists db_last_half; then " \
                "echo Last boot was not likely a success: evaluating dual-boot halves for swap eligibility...; " \
                "if ext4load mmc ${mmcdev}:$dbv_dual_data_partition ${db_id_a_addr} .sys/a.id; then " \
                    "if ext4load mmc ${mmcdev}:$dbv_dual_data_partition ${db_id_b_addr} .sys/b.id; then " \
                        "cmp.b ${db_id_a_addr} ${db_id_b_addr} ${db_id_cmp_size}; " \
                    "fi; " \
                "fi; " \
            "else " \
                "false; " \
            "fi; " \
        "fi;\0" \
    "fitaddr=0x48000000\0" \
    "fitimage=fit.img\0" \
    "kernel_addr_r=0x48000000\0" \
    "gemini_hw_detect=echo Gemini hardware detection report: gpioid=${"GEMINI_ENVVAR_BOARD_GPIOID"}, boardid=${"GEMINI_ENVVAR_BOARD_ID"}; " \
        "if test -z \"${"GEMINI_ENVVAR_FORCED_BOARD_ID"}\"; then " \
            "if test -n \"${"GEMINI_ENVVAR_BOARD_ID"}\" ; then " \
                "gemini_fdt_file=${"GEMINI_ENVVAR_BOARD_ID"}.dtb; " \
                "gemini_fit_conf=${"GEMINI_ENVVAR_BOARD_ID"}; " \
            "else " \
                "gemini_fdt_file=${fdtfile}; " \
                "gemini_fit_conf=\"conf-default\"; " \
            "fi; " \
        "else " \
            "gemini_fdt_file=${"GEMINI_ENVVAR_FORCED_BOARD_ID"}.dtb; " \
            "gemini_fit_conf=${"GEMINI_ENVVAR_FORCED_BOARD_ID"}; " \
        "fi; " \
        "setenv "GEMINI_ENVVAR_HWDETECT_BOOTARGS" \""GEMINI_ENVVAR_BOARD_GPIOID"=${"GEMINI_ENVVAR_BOARD_GPIOID"} "GEMINI_ENVVAR_BOARD_ID"=${"GEMINI_ENVVAR_BOARD_ID"} "GEMINI_ENVVAR_FORCED_BOARD_ID"=${"GEMINI_ENVVAR_FORCED_BOARD_ID"}\"\0" \
    "loadfit=echo Attempting load of FIT image (${fitimage})...; " \
        "ext4load mmc ${mmcdev}:${mmcpart} ${fitaddr} ${fitimage}\0" \
    "fitboot=env set loadaddr ${fitaddr}; " \
        "bootm ${fitaddr}#${gemini_fit_conf}\0" \
    "bsp_bootcmd=echo Running BSP bootcmd...; " \
        "run gemini_hw_detect; " \
        "run pxeboot; " \
        "mmc dev ${mmcdev}; " \
        "if mmc rescan; " \
        "run mmcargs; " \
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
                    "run mmcboot; " \
                "else " \
                    "run pxeboot_nocheck; " \
                "fi; " \
            "fi; " \
        "fi\0" \
    "loadimage=echo Attempting load of image (${image})...; " \
        "ext4load mmc ${mmcdev}:${mmcpart} ${loadaddr} ${image}\0" \
    "loadfdt=echo Attempting load of DT (${gemini_fdt_file})...; " \
        "ext4load mmc ${mmcdev}:${mmcpart} ${fdt_addr_r} ${gemini_fdt_file}\0" \
    "mmcargs=echo Evaluating dual boot...; " \
        "dbv_dual=\"\" ; " \
        "dbv_dual_partitions=\"\" ; " \
        "dbv_dual_files=\"\" ; " \
        "dbv_dual_data_partition=\"\" ; " \
        "if ext4ls mmc ${mmcdev}:3 ; then " \
            "dbv_dual=1 ; " \
            "dbv_dual_partitions=1 ; " \
            "dbv_dual_data_partition=3 ; " \
        "elif test -e mmc ${mmcdev}:1 fit.img.a || test -e mmc ${mmcdev}:1 Image.a ; then " \
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
                "setenv mmcpart 2 ; " \
            "else " \
                "setenv mmcpart 1 ; " \
            "fi; " \
            "if test -n \"$dbv_dual_files\" ; then " \
                "setenv image ${image}.${db_active_half} ; " \
                "setenv initrd ${initrd}.${db_active_half} ;  " \
                "setenv fitimage ${fitimage}.${db_active_half} ; " \
                "gemini_fdt_file=${gemini_fdt_file}.${db_active_half} ; " \
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
        "setenv mmcroot /dev/mmcblk${mmcdev}p${mmcpart} rootwait rw ; " \
        "setenv bootargs ${bootargs_extra} ${jh_clk} ${mcore_clk} console=${console} root=${mmcroot} ${"GEMINI_ENVVAR_HWDETECT_BOOTARGS"} ${dbargs}\0" \
    "mmcboot=echo Booting from mmc...; " \
         "if run loadfdt; " \
        "then " \
            "if run loadinitrd; " \
            "then " \
                "echo initrd loaded successfully... booting...; " \
                "booti ${loadaddr} ${initrd_addr} ${fdt_addr_r}; " \
            "else " \
                "echo initrd not available... booting...; " \
                "booti ${loadaddr} - ${fdt_addr_r}; " \
            "fi; " \
        "fi\0" \
    "pxeboot=echo Booting from PXE...; " \
        "if env exists pxe_disabled && itest $pxe_disabled == 1; then " \
            "echo PXE disabled (by environment); " \
        "elif test -e mmc ${mmcdev}:2 .sys/pxe.disabled || test -e mmc ${mmcdev}:3 .sys/pxe.disabled ; then " \
            "echo PXE disabled (by file-system); " \
        "else " \
            "echo Attempting PXE...; " \
            "dhcp; " \
            "if pxe get; then " \
                "echo PXE server found: attempting boot from PXE...; " \
                "pxe boot; " \
                "echo Boot from PXE server failed: attempting other boot sources...; " \
            "else " \
                "echo Cannot find PXE server: attempting other boot sources...; " \
            "fi; " \
        "fi\0" \
    "pxeboot_nocheck=echo Booting from PXE...; " \
        "dhcp; " \
        "if pxe get; then " \
            "echo PXE server found: attempting boot from PXE...; " \
            "pxe boot; " \
            "echo Boot from PXE server failed; " \
        "else " \
            "echo Cannot find PXE server: boot failed; " \
        "fi\0"

#endif