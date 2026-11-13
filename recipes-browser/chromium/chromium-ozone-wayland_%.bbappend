FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
#//!! SRC_URI:append:imxgpu = " file://0001-fix-dri-driver-dir-for-imxgpu.patch"
SRC_URI:append:imxgpu = " file://0002-fix-dri-driver-dir-for-imxgpu-in-gpu-sandbox.patch"

# Remove flags from Chromium compilation to be free to set them at command line
CHROMIUM_EXTRA_ARGS:remove = " --disable-gpu-rasterization"
CHROMIUM_EXTRA_ARGS:append = " --in-process-gpu --disable-features=VizDisplayCompositor --flag-switches-begin --enable-features=CanvasOopRasterization --flag-switches-end"