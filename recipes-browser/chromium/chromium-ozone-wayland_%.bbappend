# Remove flags from Chromium compilation to be free to set them at command line
CHROMIUM_EXTRA_ARGS:remove = " --disable-features=VizDisplayCompositor --in-process-gpu --disable-gpu-rasterization"