do_compile:append () {

    for type in ${UBOOT_CONFIG}; do
        if [ "${@d.getVarFlags('UBOOT_DTB_NAME')}" = "None" ]; then
            UBOOT_DTB_NAME_FLAGS="${type}:${UBOOT_DTB_NAME}"
        else
            UBOOT_DTB_NAME_FLAGS="${@' '.join(flag + ':' + dtb for flag, dtb in (d.getVarFlags('UBOOT_DTB_NAME')).items()) if d.getVarFlags('UBOOT_DTB_NAME') is not None else '' }"
        fi

        for key_value in ${UBOOT_DTB_NAME_FLAGS}; do
            type_key="${key_value%%:*}"
            dtb_name="${key_value#*:}"

            if [ "$type_key" = "$type" ]
            then
                bbnote "UBOOT_CONFIG = $type, UBOOT_DTB_NAME = $dtb_name"

                UBOOT_CONFIG_EXTRA="$type_key"
                if [ -e ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${dtb_name}-${type} ] ; then
                    UBOOT_DTB_NAME_EXTRA="${dtb_name}-${type}"
                else
                    # backward compatibility
                    UBOOT_DTB_NAME_EXTRA="${dtb_name}"
                fi
                UBOOT_NAME_EXTRA="u-boot-${MACHINE}.bin-${UBOOT_CONFIG_EXTRA}"
                BOOT_CONFIG_MACHINE_EXTRA="${BOOT_NAME}${BOOT_VARIANT}-${MACHINE}-${UBOOT_CONFIG_EXTRA}.bin"

                for target in ${IMXBOOT_TARGETS}; do
                    compile_${SOC_FAMILY}
                    case $target in
                    *no_v2x)
                        # Special target build for i.MX 8DXL with V2X off
                        bbnote "building ${IMX_BOOT_SOC_TARGET} - ${REV_OPTION} V2X=NO ${target}"
                        make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} V2X=NO dtbs=${UBOOT_DTB_NAME_EXTRA} print_fit_hab > ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${target}.no_v2x.print_fit_hab
                        ;;
                    *stmm_capsule)
                        bbnote "building ${IMX_BOOT_SOC_TARGET} - TEE=tee.bin-stmm ${target}"
                        make SOC=${IMX_BOOT_SOC_TARGET} TEE=tee.bin-stmm dtbs=${UBOOT_DTB_NAME_EXTRA} ${REV_OPTION} print_fit_hab > ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${target}.stmm_capsule.print_fit_hab
                        ;;
                    *)
                        bbnote "building ${IMX_BOOT_SOC_TARGET} - ${REV_OPTION} ${MKIMAGE_EXTRA_ARGS} ${target}"
                        make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} ${MKIMAGE_EXTRA_ARGS} dtbs=${UBOOT_DTB_NAME_EXTRA} print_fit_hab > ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${target}.print_fit_hab
                        ;;
                    esac
                done

                unset UBOOT_CONFIG_EXTRA
                unset UBOOT_DTB_NAME_EXTRA
                unset UBOOT_NAME_EXTRA
                unset BOOT_CONFIG_MACHINE_EXTRA
            fi

            unset type_key
            unset dtb_name
        done

        unset UBOOT_DTB_NAME_FLAGS
    done
    unset type
}