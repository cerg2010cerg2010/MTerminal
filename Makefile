DEPLOYMENT_TARGET = 12.0

# arm64 only: the current toolchain can't emit the old-ABI arm64e needed for
# iOS < 14, and arm64e devices run the arm64 slice fine.
ARCHS = arm64
TARGET = iphone:clang:latest:$(DEPLOYMENT_TARGET)
SYSROOT = $(THEOS)/sdks/iPhoneOS14.5.sdk
INSTALL_TARGET_PROCESSES = MTerminal

# Resources/ is copied into the bundle verbatim. Resources/control is a leftover
# from a pre-Theos packaging setup (the real one is ./control), so keep it out of
# the .app. The other entries mirror Theos' own default from makefiles/common.mk.
THEOS_RSYNC_EXCLUDES = _MTN .git .svn .DS_Store ._* control

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MTerminal

MTerminal_FILES = main.m MTAppDelegate.m MTController.m MTKBAvoiding.m \
	MTRowView.m MTScratchpad.m MTSettingsController.m VT100.m
MTerminal_FRAMEWORKS = UIKit CoreGraphics CoreText AudioToolbox IOKit
MTerminal_CFLAGS = -Wno-deprecated-declarations
MTerminal_CODESIGN_FLAGS = -Sentitlements.xml

include $(THEOS_MAKE_PATH)/application.mk

# Theos has no rule for Interface Builder documents, and UIKit can only load a
# compiled .storyboardc. Resources/Info.plist points UILaunchStoryboardName at
# this file, so compile it into the staged bundle by hand.
IBTOOL ?= xcrun ibtool

after-stage::
	$(ECHO_NOTHING)$(IBTOOL) --errors --warnings --notices \
		--output-format human-readable-text \
		--target-device iphone --target-device ipad \
		--minimum-deployment-target $(DEPLOYMENT_TARGET) \
		--compile "$(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/LaunchScreen.storyboardc" \
		LaunchScreen.storyboard$(ECHO_END)
