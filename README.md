# meta-gemini

This repositories is a bitbake meta-layer for gemini platform.

While checking things out, please verify that everything is according to the following versioning table:


| layer branch | Yocto release | NXP i.MX release manifest | Notes |
| :----------: | :-----------: | :-----------------------: | :---- |
| 2024.1       | scarthgap     | 6.6.36-2.1.0              | |
| master       | mickledore    | legacy                    | |


Instructions contained in this README should always be aligned with the most recent branch (the first in the table); however please verify: you've been warned!


## Setup environment

### Machine preparation
- `sudo apt update`
- `sudo apt upgrade`
- `sudo apt install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio xterm rsync curl zstd xz-utils python2-minimal python3 python3-pip python3-pexpect python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev debianutils iputils-ping lz4 libssl-dev python-is-python3 locales`
- `sudo locale-gen en-US.UTF-8`

### Machine preparation (if chromium is also required)
- `sudo apt install flex bison gperf build-essential zlib1g-dev lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev tofrodos libxml2-utils xsltproc gcc-multilib g++-multilib subversion openssh-server openssh-client uuid uuid-dev zlib1g-dev liblz-dev lzop liblzo2-2 liblzo2-dev git-core curl python3 python3-pip python3-pexpect python3-git python3-jinja2 u-boot-tools mtd-utils openjdk-8-jdk device-tree-compiler aptitude libcurl4-openssl-dev nss-updatedb chrpath texinfo gawk cpio diffstat libncursesw5-dev libssl-dev libegl1-mesa net-tools libsdl1.2-dev xterm socat icedtea-netx-common icedtea-netx`

### repo preparation
- `mkdir ~/bin`
- `curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo`
- `chmod a+x ~/bin/repo`
- add `export PATH=~/bin:$PATH` to `~/.bashrc`

### Yocto preparation
- `mkdir -p /data/imx-yocto-bsp`
- `cd /data/imx-yocto-bsp`
- `repo init -u https://github.com/nxp-imx/imx-manifest -b imx-linux-scarthgap -m imx-6.6.36-2.1.0.xml`
- `repo sync`

### meta-gemini preparation
- `cd /data/imx-yocto-bsp`
- `git clone -b 2024.1 https://github.com/morixhub/meta-gemini.git`
- `cd /data/imx-yocto-bsp/sources`
- `bitbake-layers add-layer meta-gemini`

### Yocto environment setup
- `DISTRO=fsl-imx-wayland MACHINE=imx8mp-lpddr4-evk source imx-setup-release.sh -b build`
- Add following lines to `conf/local.conf`:
  - `BBMASK += "/meta-browser/meta-chromium/recipes-browser/chromium/gn-native_.*\.bb"` (this part is requested for forcing `qtwebengine` to use its own gn-native instead the one coming from chromium; but this settings is not compatible with chromium itself... so firstly compile the image without this line and without `qtwebengine`; then after the image is cooked, add this line and `qtwebengine` and compile the image again)
  
### Multiconfig setup
- `cp -rf ../sources/meta-gemini/multiconfig .`

### Image cooking
Image cooking takes advantage of BitBake's multiconfig features, so command can be placed in the format `mc:<config_name>:<recipe>`, such as:
- `bitbake mc:aesys-2319a:aesys-qt6-image`

# Useful notes
## Chromium settings
- remove `--disable-features=VizDisplayCompositor --in-process-gpu --disable-gpu-rasterization` from `CHROMIUM_EXTRA_FLAGS` in `meta-imx/meta-sdk/dynamic-layers/chromium-browser-layer/recipes-browser/chromium/chromium-ozone-wayland_%.bbappend` (for being able to change the full configuration directly on chromium command line) (currently managed in `recipes-browser/chromium/chromium-ozone-wayland_%.bbappend` recipe)
- Chromium flags:
  - `#enable-rdrc=enabled`
  - `#canvas-oop-rasterization=enabled`
  - `#enable-raw-draw=enabled`
  
## Image writing on uSD
- `zstdcat <imagename>.wic.zst | pv | sudo dd of=/dev/sdX bs=1M conv=fsync`

## Qt6 toolchain
- add `qtwebengine` (and others, if requested) to `RDEPENDS:{PN}` in `sources/meta-qt6/recipes-qt/packagegroups/packagegroup-qt6-modules.bb` (currently managed in `recipes-qt/packagegroups/packagegroup-qt6-modules.bbappend` recipe)
- `bitbake meta-toolchain-qt6`
