#ifndef __GEMINI_ENV_H
#define __GEMINI_ENV_H

#define GEMINI_ENV \
	"bootcmd=run bsp_bootcmd\0" \
	"initrd=initram.img\0" \
	"initrd_addr=0x43800000\0" \
	"loadinitrd=echo Attempting load of initrd...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${initrd_addr} ${initrd}\0" \
	"fitaddr=0x48000000\0" \
	"fitimage=fit.img\0" \
	"loadfit=echo Attempting loading of FIT image...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${fitaddr} ${fitimage}\0" \
	"fitboot=env set loadaddr ${fitaddr}; " \
		"bootm ${fitaddr}\0" \
	"bsp_bootcmd=echo Running BSP bootcmd...; " \
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
	"loadbootscript=echo Attempting loading bootscript...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${loadaddr} ${bsp_script};\0" \
	"bootscript=echo Running bootscript from mmc ...; " \
		"source\0" \
	"loadimage=echo Attempting loading of image...; " \
		"ext4load mmc ${mmcdev}:${mmcpart} ${loadaddr} ${image}\0" \
    "mmcargs=if ext4ls mmc ${mmcdev}:3 ; then " \
			"echo DUAL BOOT MODE ; " \
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
			"if test ${db_last_half} = b ; then " \
				"setenv mmcpart 2 ;" \
			"else " \
				"setenv mmcpart 1 ; " \
			"fi; " \
			"setenv dbargs db_current_half=${db_current_half} ; " \
            "if test -n \"${db_force_single}\" ; then " \
                "setenv dbargs ${dbargs} db_force_single ; " \
            "fi; " \
		"else " \
			"echo SINGLE BOOT MODE ; " \
		"fi; " \
		"setenv mmcroot /dev/mmcblk${mmcdev}p${mmcpart} rootwait rw ; " \
		"setenv bootargs ${jh_clk} ${mcore_clk} console=${console} root=${mmcroot} ${dbargs}\0" \
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