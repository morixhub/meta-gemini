// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright 2019 NXP
 */

#include <common.h>
#include <efi_loader.h>
#include <env.h>
#include <init.h>
#include <asm/global_data.h>
#include <miiphy.h>
#include <netdev.h>
#include <asm/mach-imx/iomux-v3.h>
#include <asm-generic/gpio.h>
#include <asm/arch/imx8mn_pins.h>
#include <asm/arch/clock.h>
#include <asm/arch/sys_proto.h>
#include <asm/mach-imx/gpio.h>
#include <asm/mach-imx/mxc_i2c.h>
#include <i2c.h>
#include <asm/io.h>
#include "../common/tcpc.h"
#include <usb.h>
#include <asm/arch-imx8m/imx-regs.h>
#include <linux/libfdt.h>
#include <fdt_support.h>

DECLARE_GLOBAL_DATA_PTR;

#define UFCR 0x0090
#define UFCR_DCEDTE    (1<<6)  /* DTE mode select */

#define UART_PAD_CTRL	(PAD_CTL_DSE6 | PAD_CTL_FSEL1)
#define WDOG_PAD_CTRL	(PAD_CTL_DSE6 | PAD_CTL_ODE | PAD_CTL_PUE | PAD_CTL_PE)

#define HWREV_PAD_CTRL_NOPULL	(PAD_CTL_DSE6)
#define HWREV_PAD_CTRL_PULL_UP	(PAD_CTL_DSE6 | PAD_CTL_PUE | PAD_CTL_PE)
#define HWREV_PAD_CTRL_PULL_DOWN	(PAD_CTL_DSE6 | PAD_CTL_PE)

static iomux_v3_cfg_t const uart_pads_dte[] = {
	IMX8MN_PAD_SAI3_TXC__UART2_DTE_RX | MUX_PAD_CTRL(UART_PAD_CTRL),
	IMX8MN_PAD_SAI3_TXFS__UART2_DTE_TX | MUX_PAD_CTRL(UART_PAD_CTRL),
};

static iomux_v3_cfg_t const uart_pads_dce[] = {
	IMX8MN_PAD_SAI3_TXC__UART2_DCE_TX | MUX_PAD_CTRL(UART_PAD_CTRL),
	IMX8MN_PAD_SAI3_TXFS__UART2_DCE_RX | MUX_PAD_CTRL(UART_PAD_CTRL),
};

static iomux_v3_cfg_t const wdog_pads[] = {
	IMX8MN_PAD_GPIO1_IO02__WDOG1_WDOG_B  | MUX_PAD_CTRL(WDOG_PAD_CTRL),
};

// GPIO defines
#define GPIO_DR     0x00
#define GPIO_GDIR   0x04
#define GPIO_PSR    0x08

// GPIO banks base on i.MX8MN
static const u32 gpio_bases[] = {
    0x30200000, // GPIO1
    0x30210000, // GPIO2
    0x30220000, // GPIO3
    0x30230000, // GPIO4
    0x30240000  // GPIO5
};

struct gpio_t {
	const int bank;
	const int number;
};

static struct gpio_t const hwrev_gpios[] = {
	{ 2, 9 }, // HW_REV7
	{ 2, 8 }, // HW_REV6
	{ 2, 7 }, // HW_REV5
	{ 2, 6 }, // HW_REV4
	{ 2, 5 }, // HW_REV3
	{ 2, 4 }, // HW_REV2
	{ 2, 3 }, // HW_REV1
	{ 2, 2 }, // HW_REV0
};

static iomux_v3_cfg_t const hwrev_pads[] = {
	IMX8MN_PAD_SD1_DATA7__GPIO2_IO9,
	IMX8MN_PAD_SD1_DATA6__GPIO2_IO8,
	IMX8MN_PAD_SD1_DATA5__GPIO2_IO7,
	IMX8MN_PAD_SD1_DATA4__GPIO2_IO6,
	IMX8MN_PAD_SD1_DATA3__GPIO2_IO5,
	IMX8MN_PAD_SD1_DATA2__GPIO2_IO4,
	IMX8MN_PAD_SD1_DATA1__GPIO2_IO3,
	IMX8MN_PAD_SD1_DATA0__GPIO2_IO2,
};

#define HWREV_GPIOID_SIZE 8
#define HWREV_BOARDID_MAXSIZE 32

struct hwrev_t {
	const char *gpioid;
	const char *boardid;
};

static struct hwrev_t const hwrevs[] = {
	{ "00000001", "aesys_2409a" },
	{ "10000001", "aesys_2409c" },
};

#ifdef CONFIG_NAND_MXS
#ifdef CONFIG_SPL_BUILD
#define NAND_PAD_CTRL	(PAD_CTL_DSE6 | PAD_CTL_FSEL2 | PAD_CTL_HYS)
#define NAND_PAD_READY0_CTRL (PAD_CTL_DSE6 | PAD_CTL_FSEL2 | PAD_CTL_PUE)
static iomux_v3_cfg_t const gpmi_pads[] = {
	IMX8MN_PAD_NAND_ALE__RAWNAND_ALE | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_CE0_B__RAWNAND_CE0_B | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_CLE__RAWNAND_CLE | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_DATA00__RAWNAND_DATA00 | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_DATA01__RAWNAND_DATA01 | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_DATA02__RAWNAND_DATA02 | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_DATA03__RAWNAND_DATA03 | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_DATA04__RAWNAND_DATA04 | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_DATA05__RAWNAND_DATA05	| MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_DATA06__RAWNAND_DATA06	| MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_DATA07__RAWNAND_DATA07	| MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_RE_B__RAWNAND_RE_B | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_READY_B__RAWNAND_READY_B | MUX_PAD_CTRL(NAND_PAD_READY0_CTRL),
	IMX8MN_PAD_NAND_WE_B__RAWNAND_WE_B | MUX_PAD_CTRL(NAND_PAD_CTRL),
	IMX8MN_PAD_NAND_WP_B__RAWNAND_WP_B | MUX_PAD_CTRL(NAND_PAD_CTRL),
};
#endif

static void setup_gpmi_nand(void)
{
#ifdef CONFIG_SPL_BUILD
	imx_iomux_v3_setup_multiple_pads(gpmi_pads, ARRAY_SIZE(gpmi_pads));
#endif

	init_nand_clk();
}
#endif

#if CONFIG_IS_ENABLED(EFI_HAVE_CAPSULE_SUPPORT)
struct efi_fw_image fw_images[] = {
	{
		.image_type_id = IMX_BOOT_IMAGE_GUID,
		.fw_name = u"AESYS-2409A-RAW",
		.image_index = 1,
	},
};

struct efi_capsule_update_info update_info = {
	.dfu_string = "mmc 2=flash-bin raw 0 0x2000 mmcpart 1",
	.num_images = ARRAY_SIZE(fw_images),
	.images = fw_images,
};

#endif /* EFI_HAVE_CAPSULE_SUPPORT */

int imx_read_gpio_input(int bank, int pin)
{
    u32 base_addr;
    u32 val;

	// Check input
    if (bank < 1 || bank > 5 || pin < 0 || pin > 31)
        return -EINVAL;

	// Retrieve GPIO bank base address
    base_addr = gpio_bases[bank - 1];

	// Ensure GPIO is configured as input
    clrbits_le32(base_addr + GPIO_GDIR, (1 << pin));

	// Read GPIO value
    val = readl(base_addr + GPIO_PSR);

    return (val & (1 << pin)) ? 1 : 0;
}

void detect_board(char* gpioid, char* boardid)
{
	// Declare vars
	int i;
	int pdn[HWREV_GPIOID_SIZE];
	
	// Initialize vars
	memset(gpioid, 0, (HWREV_GPIOID_SIZE + 1));
	memset(boardid, 0, (HWREV_BOARDID_MAXSIZE + 1));

	// 1) Set hwrev pads to pull-down & read GPIO values
	for (i = 0; i < HWREV_GPIOID_SIZE; i++) {
		imx_iomux_v3_setup_pad(hwrev_pads[i] | MUX_PAD_CTRL(HWREV_PAD_CTRL_PULL_DOWN));
		pdn[i] = imx_read_gpio_input(hwrev_gpios[i].bank, hwrev_gpios[i].number);
	}

	// 3) Finalize GPIOID string
	for (i = 0; i < HWREV_GPIOID_SIZE; i++) {
		gpioid[i] = (pdn[i] ? '1' : '0');
	}

	// 4) Determine board ID
	for (i = 0; i < ARRAY_SIZE(hwrevs); i++) {
		if(strcmp(hwrevs[i].gpioid, gpioid) == 0) {
			strncpy(boardid, hwrevs[i].boardid, HWREV_BOARDID_MAXSIZE);
			return;
		}
	}

	// 5) Provide default if here
	strncpy(boardid, hwrevs[0].boardid, HWREV_BOARDID_MAXSIZE);
}

#ifdef CONFIG_OF_BOARD_FIXUP
#ifdef CONFIG_OF_CUSTOM_BOARD_FIXUP
int custom_board_fix_fdt(void *rw_fdt_blob)
{
	int nodeoffset;

	gd->arch.custom_board_fixup_status = 1;

	nodeoffset = fdt_path_offset(rw_fdt_blob, "/soc@0/bus@30800000/spba-bus@30800000/serial@30890000");
	if(nodeoffset >= 0)
	{
		gd->arch.custom_board_fixup_status = 2;

		// Detect board
		char gpioid[HWREV_GPIOID_SIZE + 1];
		char boardid[HWREV_BOARDID_MAXSIZE + 1];
		detect_board(gpioid, boardid);
		
		// Initialize console UART
		if(strcmp(boardid, "aesys_2409c") == 0)
		{
			gd->arch.custom_board_fixup_status = 3;

			imx_iomux_v3_setup_multiple_pads(uart_pads_dce, ARRAY_SIZE(uart_pads_dce));
			fdt_delprop((void*)rw_fdt_blob, nodeoffset, "fsl,dte-mode");
		}
		else
		{
			gd->arch.custom_board_fixup_status = 4;

			imx_iomux_v3_setup_multiple_pads(uart_pads_dte, ARRAY_SIZE(uart_pads_dte));
			fdt_setprop_empty((void*)rw_fdt_blob, nodeoffset, "fsl,dte-mode");
		}
	}

	return 0;
}
#endif
#endif

int board_early_init_f(void)
{
	// Initialize WDOG
	struct wdog_regs *wdog = (struct wdog_regs *)WDOG1_BASE_ADDR;
	imx_iomux_v3_setup_multiple_pads(wdog_pads, ARRAY_SIZE(wdog_pads));
	set_wdog_reset(wdog);

	// Initialize UART clock
	init_uart_clk(1);

#ifdef CONFIG_NAND_MXS
	setup_gpmi_nand(); /* SPL will call the board_early_init_f */
#endif

	return 0;
}

#if IS_ENABLED(CONFIG_FEC_MXC)
static int setup_fec(void)
{
	struct iomuxc_gpr_base_regs *gpr =
		(struct iomuxc_gpr_base_regs *)IOMUXC_GPR_BASE_ADDR;

	/* Use 50MHz clock for external */
	/* BIT13: */
	/*   0: ENET_TD2 is input (clock from external source) */
	/*   1: ENET_TD2 is output */
	clrsetbits_le32(&gpr->gpr[1], IOMUXC_GPR_GPR1_GPR_ENET1_TX_CLK_SEL, 0);
	return(0);

	/*
	 * Replace the previous instructions with these ones for ENET_TD2 working as output
	 *
	setbits_le32(&gpr->gpr[1], IOMUXC_GPR_GPR1_GPR_ENET1_TX_CLK_SEL);
	return(set_clk_enet(ENET_50MHZ));
	*/
}

int board_phy_config(struct phy_device *phydev)
{
	if (phydev->drv->config)
		phydev->drv->config(phydev);

#ifndef CONFIG_DM_ETH
	/* ATTENTION: Following lines are removed because we do not want to manage RGMII mode on this board */

	/* enable rgmii rxc skew and phy mode select to RGMII copper */
	/* 
	phy_write(phydev, MDIO_DEVAD_NONE, 0x1d, 0x1f);
	phy_write(phydev, MDIO_DEVAD_NONE, 0x1e, 0x8);

	phy_write(phydev, MDIO_DEVAD_NONE, 0x1d, 0x00);
	phy_write(phydev, MDIO_DEVAD_NONE, 0x1e, 0x82ee);
	phy_write(phydev, MDIO_DEVAD_NONE, 0x1d, 0x05);
	phy_write(phydev, MDIO_DEVAD_NONE, 0x1e, 0x100);
	*/
#endif

	return 0;
}
#endif

#ifdef CONFIG_USB_TCPC
struct tcpc_port port1;
struct tcpc_port port2;

static int setup_pd_switch(uint8_t i2c_bus, uint8_t addr)
{
	struct udevice *bus;
	struct udevice *i2c_dev = NULL;
	int ret;
	uint8_t valb;

	ret = uclass_get_device_by_seq(UCLASS_I2C, i2c_bus, &bus);
	if (ret) {
		printf("%s: Can't find bus\n", __func__);
		return -EINVAL;
	}

	ret = dm_i2c_probe(bus, addr, 0, &i2c_dev);
	if (ret) {
		printf("%s: Can't find device id=0x%x\n",
			__func__, addr);
		return -ENODEV;
	}

	ret = dm_i2c_read(i2c_dev, 0xB, &valb, 1);
	if (ret) {
		printf("%s dm_i2c_read failed, err %d\n", __func__, ret);
		return -EIO;
	}
	valb |= 0x4; /* Set DB_EXIT to exit dead battery mode */
	ret = dm_i2c_write(i2c_dev, 0xB, (const uint8_t *)&valb, 1);
	if (ret) {
		printf("%s dm_i2c_write failed, err %d\n", __func__, ret);
		return -EIO;
	}

	/* Set OVP threshold to 23V */
	valb = 0x6;
	ret = dm_i2c_write(i2c_dev, 0x8, (const uint8_t *)&valb, 1);
	if (ret) {
		printf("%s dm_i2c_write failed, err %d\n", __func__, ret);
		return -EIO;
	}

	return 0;
}

int pd_switch_snk_enable(struct tcpc_port *port)
{
	if (port == &port1) {
		debug("Setup pd switch on port 1\n");
		return setup_pd_switch(1, 0x72);
	} else if (port == &port2) {
		debug("Setup pd switch on port 2\n");
		return setup_pd_switch(1, 0x73);
	} else
		return -EINVAL;
}

struct tcpc_port_config port1_config = {
	.i2c_bus = 1, /*i2c2*/
	.addr = 0x50,
	.port_type = TYPEC_PORT_UFP,
	.max_snk_mv = 5000,
	.max_snk_ma = 3000,
	.max_snk_mw = 40000,
	.op_snk_mv = 9000,
	.switch_setup_func = &pd_switch_snk_enable,
};

struct tcpc_port_config port2_config = {
	.i2c_bus = 1, /*i2c2*/
	.addr = 0x52,
	.port_type = TYPEC_PORT_UFP,
	.max_snk_mv = 9000,
	.max_snk_ma = 3000,
	.max_snk_mw = 40000,
	.op_snk_mv = 9000,
	.switch_setup_func = &pd_switch_snk_enable,
};

static int setup_typec(void)
{
	int ret;

	debug("tcpc_init port 2\n");
	ret = tcpc_init(&port2, port2_config, NULL);
	if (ret) {
		printf("%s: tcpc port2 init failed, err=%d\n",
		       __func__, ret);
	} else if (tcpc_pd_sink_check_charging(&port2)) {
		/* Disable PD for USB1, since USB2 has priority */
		port1_config.disable_pd = true;
		printf("Power supply on USB2\n");
	}

	debug("tcpc_init port 1\n");
	ret = tcpc_init(&port1, port1_config, NULL);
	if (ret) {
		printf("%s: tcpc port1 init failed, err=%d\n",
		       __func__, ret);
	} else {
		if (!port1_config.disable_pd)
			printf("Power supply on USB1\n");
		return ret;
	}

	return ret;
}

int board_usb_init(int index, enum usb_init_type init)
{
	int ret = 0;
	struct tcpc_port *port_ptr;

	debug("board_usb_init %d, type %d\n", index, init);

	if (index == 0)
		port_ptr = &port1;
	else
		port_ptr = &port2;

	imx8m_usb_power(index, true);

	if (init == USB_INIT_HOST)
		tcpc_setup_dfp_mode(port_ptr);
	else
		tcpc_setup_ufp_mode(port_ptr);

	return ret;
}

int board_usb_cleanup(int index, enum usb_init_type init)
{
	int ret = 0;

	debug("board_usb_cleanup %d, type %d\n", index, init);

	if (init == USB_INIT_HOST) {
		if (index == 0)
			ret = tcpc_disable_src_vbus(&port1);
		else
			ret = tcpc_disable_src_vbus(&port2);
	}

	imx8m_usb_power(index, false);
	return ret;
}

int board_ehci_usb_phy_mode(struct udevice *dev)
{
	int ret = 0;
	enum typec_cc_polarity pol;
	enum typec_cc_state state;
	struct tcpc_port *port_ptr;

	if (dev_seq(dev) == 0)
		port_ptr = &port1;
	else
		port_ptr = &port2;

	tcpc_setup_ufp_mode(port_ptr);

	ret = tcpc_get_cc_status(port_ptr, &pol, &state);
	if (!ret) {
		if (state == TYPEC_STATE_SRC_RD_RA || state == TYPEC_STATE_SRC_RD)
			return USB_INIT_HOST;
	}

	return USB_INIT_DEVICE;
}

#endif

int board_init(void)
{
#ifdef CONFIG_USB_TCPC
	setup_typec();
#endif

	if (IS_ENABLED(CONFIG_FEC_MXC))
		setup_fec();

	return 0;
}

int board_late_init(void)
{
#ifdef CONFIG_ENV_IS_IN_MMC
	board_late_mmc_env_init();
#endif

#ifdef CONFIG_ENV_VARS_UBOOT_RUNTIME_CONFIG
	env_set("board_name", "EVK");
	env_set("board_rev", "iMX8MN");
#endif

	// Detect board
	char gpioid[HWREV_GPIOID_SIZE + 1];
	char boardid[HWREV_BOARDID_MAXSIZE + 1];
	detect_board(gpioid, boardid);

#ifdef CONFIG_OF_BOARD_FIXUP
	printf("Compiled with board FIXUP\n");
#ifdef CONFIG_OF_CUSTOM_BOARD_FIXUP
	printf("Compiled with custom board FIXUP (status=%lu)\n", gd->arch.custom_board_fixup_status);
#endif
#endif

	printf("Detected gpioid: %s\n", gpioid);
	printf("Detected boardid: %s\n", boardid);

	// Set environment variables for gpioid and boardid
	env_set(GEMINI_ENVVAR_BOARD_GPIOID, gpioid);
	env_set(GEMINI_ENVVAR_BOARD_ID, boardid);

	return 0;
}

#ifdef CONFIG_ANDROID_SUPPORT
bool is_power_key_pressed(void) {
	return (bool)(!!(readl(SNVS_HPSR) & (0x1 << 6)));
}
#endif

#ifdef CONFIG_FSL_FASTBOOT
#ifdef CONFIG_ANDROID_RECOVERY
int is_recovery_key_pressing(void)
{
	return 0; /* TODO */
}
#endif /* CONFIG_ANDROID_RECOVERY */
#endif /* CONFIG_FSL_FASTBOOT */
