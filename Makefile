FW_DEVICE_IP = 192.168.1.9
ARCHS = armv7 arm64
SDKVERSION = 9.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 9.0
SYSROOT = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.0.sdk

PACKAGE_VERSION = 1.2.3

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

TWEAK_NAME = SB3DTouchMenu
SB3DTouchMenu_FILES = Tweak.xm \
					  SB3DTMSwitcherForceLongPressPanGestureRecognizer.xm \
					  SB3DTMScreenEdgeLongPressPanGestureRecognizer.xm
SB3DTouchMenu_FRAMEWORKS = UIKit AudioToolbox CoreMedia
SB3DTouchMenu_LIBRARIES = Accessibility MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"

ri:: remoteinstall
remoteinstall:: all internal-remoteinstall after-remoteinstall
internal-remoteinstall::
	ssh root@$(FW_DEVICE_IP) "rm -f /Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).dylib"
	scp -P 22 "$(FW_PROJECT_DIR)/$(THEOS_OBJ_DIR_NAME)/$(TWEAK_NAME).dylib" root@$(FW_DEVICE_IP):/Library/MobileSubstrate/DynamicLibraries/
	scp -P 22 "$(FW_PROJECT_DIR)/$(TWEAK_NAME).plist" root@$(FW_DEVICE_IP):/Library/MobileSubstrate/DynamicLibraries/
after-remoteinstall::
	ssh root@$(FW_DEVICE_IP) "killall -9 backboardd"
