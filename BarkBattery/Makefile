TARGET := iphone:clang:latest:13.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += barkbattery
SUBPROJECTS += barkbatteryprefs

include $(THEOS_MAKE_PATH)/aggregate.mk
