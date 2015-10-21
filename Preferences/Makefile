FW_DEVICE_IP = 192.168.1.9
ARCHS = armv7 arm64
SDKVERSION = 9.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 9.0
SYSROOT = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.0.sdk

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SB3DTMSettings
SB3DTMSettings_FILES = SB3DTMRootListController.m
SB3DTMSettings_INSTALL_PATH = /Library/PreferenceBundles
SB3DTMSettings_FRAMEWORKS = UIKit
SB3DTMSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SB3DTMSettings.plist$(ECHO_END)
