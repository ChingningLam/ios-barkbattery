TARGET := iphone:clang:latest:13.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BarkBattery

BarkBattery_FILES = Tweak.x
BarkBattery_CFLAGS = -fobjc-arc
BarkBattery_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
