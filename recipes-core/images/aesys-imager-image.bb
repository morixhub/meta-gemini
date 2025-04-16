SUMMARY = "Aesys base image Imager tool"

inherit core-image
inherit extrausers

# Set root's password and related access control
# (encrypted password obtained with command "openssl passwd -1 ae1221")
IMAGE_FEATURES:remove = "debug-tweaks"
IMAGE_FEATURES:append = " allow-root-login "
EXTRA_USERS_PARAMS += "usermod -p '\$1\$FMup4eG7\$5kGXZnwbAA/kNnkqhHLaA1' root;" 

# Remove development tools from final image
IMAGE_FEATURES:remove = "tools-sdk"

# Normalize image name
IMAGE_NAME = "${IMAGE_LINK_NAME}-image"

# Select "tar.zst" format
IMAGE_FSTYPES = "tar.zst"

# Add features
IMAGE_FEATURES:append = " ssh-server-openssh splash "

# Add utils
IMAGE_INSTALL:append = " glibc-utils "
IMAGE_INSTALL:append = " u-boot-fw-utils "
IMAGE_INSTALL:append = " ifupdown init-ifupdown ifplugd "
IMAGE_INSTALL:append = " dhcpcd dhcpcd-recheck "
IMAGE_INSTALL:append = " dialog ncurses e2fsprogs e2fsprogs-e2fsck e2fsprogs-mke2fs e2fsprogs-resize2fs parted dosfstools htop ethtool i2c-tools iperf3 util-linux minicom nano devmem2 libgpiod-tools spidev-test nmap tcpdump evtest memtester rsync zip unzip stress-ng strace screen bc "
IMAGE_INSTALL:append = " coreutils "



