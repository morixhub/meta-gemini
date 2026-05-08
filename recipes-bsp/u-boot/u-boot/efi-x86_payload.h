// Remember to define GEMINI_PXE_UUID before including "gemini_env.h"
#define GEMINI_PXE_UUID "00000000-1234-5678-0000-000000000000"

#include "gemini_env.h"

#undef CFG_EXTRA_ENV_SETTINGS
#define CFG_EXTRA_ENV_SETTINGS \
    GEMINI_ENV
