# Remove flags from Chromium compilation to be free to set them at command line
CHROMIUM_EXTRA_ARGS:remove = " --disable-gpu-rasterization"
CHROMIUM_EXTRA_ARGS:append = " --in-process-gpu --disable-features=VizDisplayCompositor --flag-switches-begin --enable-features=CanvasOopRasterization --flag-switches-end"