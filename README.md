# meta-gemini

This repositories is a bitbake meta-layer for gemini platform



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
- `repo init -u https://github.com/nxp-imx/imx-manifest -b imx-linux-langdale -m imx-6.1.55-2.2.0.xml` (verify latest release here)
- `repo sync`

### meta-gemini preparation
- `cd /data/imx-yocto-bsp`
- `git clone https://github.com/morixhub/meta-gemini.git`
- `cd /data/imx-yocto-bsp/sources`
- `bitbake-layers add-layer meta-gemini`

### Yocto environment setup
- `DISTRO=fsl-imx-wayland MACHINE=imx8mp-lpddr4-evk source imx-setup-release.sh -b build-wayland`
- Add following lines to `conf/local.conf`:
  - `BB_NUMBER_THREADS = "15"`
  - `PARALLEL_MAKE = "-j 15"`
  - `CORE_IMAGE_EXTRA_INSTALL += "chromium-ozone-wayland"`
  - `IMAGE_INSTALL:append = "qtwebengine qtwebsockets qtmqtt qtmultimedia qtserialport qtserialbus qtwebview"`
  - `BBMASK += "/meta-browser/meta-chromium/recipes-browser/chromium/gn-native_.*\.bb"` (this part is requested for forcing `qtwebengine` to use its own gn-native instead the one coming from chromium; but this settings is not compatible with chromium itself... so firstly compile the image without this line and without `qtwebengine`; then after the image is cooked, add this line and `qtwebengine` and compile the image again)
  
### Image cooking
- `bitbake imx-image-full`


# Useful notes
## Chromium settings
- remove `--disable-features=VizDisplayCompositor --in-process-gpu --disable-gpu-rasterization` from `CHROMIUM_EXTRA_FLAGS` in `meta-imx/meta-sdk/dynamic-layers/chromium-browser-layer/recipes-browser/chromium/chromium-ozone-wayland_%.bbappend` (for being able to change the full configuration directly on chromium command line)
- Chromium flags:
  - `#enable-rdrc=enabled`
  - `#canvas-oop-rasterization=enabled`
  - `#enable-raw-draw=enabled`
  
## Image writing on uSD
- `zstdcat imx-image-full-imx8mp-lpddr4-evk.wic.zst | pv | sudo dd of=/dev/sdX bs=1M conv=fsync`

## Qt6 toolchain
- add `qtwebengine` (if requested) to `RDEPENDS_{PN}` in `sources/meta-qt6/recipes-qt/packagegroups/packagegroup-qt6-modules.bb`
- `bitbake meta-toolchain-qt6`
