TARGET := iphone:clang:latest:13.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = BarkBatteryPrefs

BarkBatteryPrefs_FILES = BBPRootListController.m
BarkBatteryPrefs_FRAMEWORKS = UIKit
BarkBatteryPrefs_PRIVATE_FRAMEWORKS = Preferences
BarkBatteryPrefs_INSTALL_PATH = /Library/PreferenceBundles
BarkBatteryPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
