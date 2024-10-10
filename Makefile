ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
SYSROOT = $(THEOS)/sdks/iPhoneOS14.5.sdk
INSTALL_TARGET_PROCESSES = MTerminal

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = MTerminal

MTerminal_XCODEFLAGS = THEOS_FLAG=-DTHEOS
MTerminal_CODESIGN_FLAGS = -Sentitlements.xml

include $(THEOS_MAKE_PATH)/xcodeproj.mk

