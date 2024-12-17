require recipes-qt/qt6/gn-native_git.bb

# This file is here for providing an alias for gn-native_git.bb because otherwise there
# is a conflict between chromium-provided gn-native and qt-provided one
#
# Then it is requested to modify all Qt recipes in order to depend on qtgn-native rather than gn-native
