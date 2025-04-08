#ifndef __GEMINI_ENV_H
#define __GEMINI_ENV_H

#define GEMINI_ENVVAR_BOARD_GPIOID "gemini_board_gpioid"
#define GEMINI_ENVVAR_BOARD_ID "gemini_board_boardid"

#define GEMINI_ENV \
	"bootcmd=run bsp_bootcmd\0" \
	"initrd=initram.img\0" \
	"initrd_addr=0x43800000\0" \
	"loadinitrd=echo Attempting load of initrd (${initrd})...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${initrd_addr} ${initrd}\0" \
	"fitaddr=0x48000000\0" \
	"fitimage=fit.img\0" \
	"gemini_hw_detect=echo Gemini hardware detection report: gpioid=${"GEMINI_ENVVAR_BOARD_GPIOID"}, boardid=${"GEMINI_ENVVAR_BOARD_ID"}; " \
	"if test -n \"${"GEMINI_ENVVAR_BOARD_ID"}\" ; then " \
		"gemini_fdt_file=${"GEMINI_ENVVAR_BOARD_ID"}.dtb; " \
		"gemini_fit_conf=${"GEMINI_ENVVAR_BOARD_ID"}; " \
	"else " \
		"gemini_fdt_file=${fdtfile}; " \
		"gemini_fit_conf=\"conf-1\"; " \
	"fi\0" \
	"loadfit=echo Attempting load of FIT image (${fitimage})...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${fitaddr} ${fitimage}\0" \
	"fitboot=env set loadaddr ${fitaddr}; " \
		"bootm ${fitaddr}#${gemini_fit_conf}\0" \
	"bsp_bootcmd=echo Running BSP bootcmd...; " \
		"run gemini_hw_detect; " \
		"mmc dev ${mmcdev}; " \
		"if mmc rescan; " \
		"run mmcargs; " \
		"then " \
			"if run loadbootscript; " \
			"then " \
				"echo bootscript available... running...; " \
				"run bootscript; " \
			"else " \
				"if run loadfit; " \
				"then " \
					"echo FIT image loaded successfully... booting...; " \
					"run fitboot; " \
				"else " \
					"if run loadimage; " \
					"then " \
						"echo Image available... continue booting...; " \
						"run mmcboot; " \
					"else " \
						"run netboot; " \
					"fi; " \
				"fi; " \
			"fi; " \
		"fi\0" \
	"loadbootscript=echo Attempting load of bootscript (${bsp_script})...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${loadaddr} ${bsp_script};\0" \
	"bootscript=echo Running bootscript from mmc ...; " \
		"source\0" \
	"loadimage=echo Attempting load of image (${image})...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${loadaddr} ${image}\0" \
	"loadfdt=echo Attempting load of DT (${gemini_fdt_file})...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${fdt_addr_r} ${gemini_fdt_file}\0" \
    "mmcargs=echo Evaluating dual boot...; " \
		"dbv_dual=\"\" ; " \
		"dbv_dual_partitions=\"\" ; " \
		"dbv_dual_files=\"\" ; " \
		"if ext4ls mmc ${mmcdev}:3 ; then " \
			"dbv_dual=1 ; " \
			"dbv_dual_partitions=1 ; " \
		"elif ext4load mmc 1:1 ${loadaddr} fit.img.a || ext4load mmc 1:1 ${loadaddr} Image.a ; then " \
			"dbv_dual=1 ; " \
			"dbv_dual_files=1 ; " \
		"fi; " \
		"if test -n \"$dbv_dual\" ; then " \
			"if test -n \"$dbv_dual_partitions\" ; then " \
				"echo DUAL BOOT MODE (partitions) ; " \
			"else " \
				"echo DUAL BOOT MODE (files) ; " \
			"fi; " \
            "if test -n \"${db_force_single}\" ; then " \
                "echo FORCING SINGLE BOOT from half A... ; " \
                "setenv db_current_half a ; " \
                "setenv db_last_half a ; " \
            "else " \
                "if env exists db_current_half && test ${db_current_half} = b ; then " \
                    "if env exists db_last_half ; then " \
                        "echo Dual booting from half A... ; " \
                        "setenv db_current_half a ; " \
                        "setenv db_last_half a ; " \
                    "else " \
                        "echo Dual booting from half B... ; " \
                        "setenv db_current_half b ; " \
                        "setenv db_last_half b ; " \
                    "fi; " \
                "else " \
                    "if env exists db_last_half ; then " \
                        "echo Dual booting from half B... ; " \
                        "setenv db_current_half b ; " \
                        "setenv db_last_half b ; " \
                    "else " \
                        "echo Dual booting from half A... ; " \
                        "setenv db_current_half a ; " \
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
				"setenv image ${image}.${db_current_half} ; " \
				"setenv initrd ${initrd}.${db_current_half} ;  " \
				"setenv fitimage ${fitimage}.${db_current_half} ; " \
				"gemini_fdt_file=${gemini_fdt_file}.${db_current_half} ; " \
			"fi; " \
			"setenv dbargs db_current_half=${db_current_half} ; " \
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
		"setenv bootargs ${jh_clk} ${mcore_clk} console=${console} root=${mmcroot} "GEMINI_ENVVAR_BOARD_GPIOID"=${"GEMINI_ENVVAR_BOARD_GPIOID"} "GEMINI_ENVVAR_BOARD_ID"=${"GEMINI_ENVVAR_BOARD_ID"} ${dbargs}\0" \
	"mmcboot=echo Booting from mmc ...; " \
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

#endif