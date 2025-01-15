# Remove dependencies on connman-tools (because we do not want it)
RDEPENDS:${PN}:remove = " \
    connman-tools \
    connman-tests \
    connman-client \
"

# Remove dependencies on pipewire due to OS hardening purposes (will imply a specific OS user "pipewire" which should be avoided)
RDEPENDS:${PN}:remove = " \
    ${PIPEWIRE_TOOLS} \
"
