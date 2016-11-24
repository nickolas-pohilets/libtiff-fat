SDK_IPHONEOS_PATH=$(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR_PATH=$(shell xcrun --sdk iphonesimulator --show-sdk-path)
SDK_MACOSX_PATH=$(shell xcrun --sdk macosx --show-sdk-path)
XCODE_DEVELOPER_PATH="`xcode-select -p`"
XCODETOOLCHAIN_PATH=$(XCODE_DEVELOPER_PATH)/Toolchains/XcodeDefault.xctoolchain
IOS_DEPLOY_TGT ?= "7.0"
MAC_DEPLOY_TGT ?= "10.10"

platforms_all = ios mac
PLATFORMS ?= $(platforms_all)

ios_sdks = $(SDK_IPHONEOS_PATH) $(SDK_IPHONEOS_PATH) $(SDK_IPHONEOS_PATH) $(SDK_IPHONESIMULATOR_PATH) $(SDK_IPHONESIMULATOR_PATH)
mac_sdks = $(SDK_MACOSX_PATH) $(SDK_MACOSX_PATH)
sdks = $(foreach platform, $(platforms_all), $($(platform)_sdks))

ios_archs_all = armv7 armv7s arm64 i386 x86_64
mac_archs_all = i386 x86_64
archs_all = $(foreach platform, $(platforms_all), $($(platform)_archs_all))

ios_host_names_all = arm-apple-darwin7 arm-apple-darwin7s arm-apple-darwin64 i386-apple-darwin x86_64-apple-darwin
mac_host_names_all = i386-apple-darwin x86_64-apple-darwin
host_names_all = $(foreach platform, $(platforms_all), $($(platform)_host_names_all))

ios_min_version = -miphoneos-version-min=$(IOS_DEPLOY_TGT)
ios_min_versions_all = $(ios_min_version) $(ios_min_version) $(ios_min_version) $(ios_min_version) $(ios_min_version)
mac_min_version = -mmacosx-version-min=$(MAC_DEPLOY_TGT)
mac_min_versions_all = $(mac_min_version) $(mac_min_version)
min_versions_all = $(foreach platform, $(platforms_all), $($(platform)_min_versions_all))

make_config_name = $(1)-$(2)
ios_config_names_all = $(foreach arch, $(ios_archs_all), $(call make_config_name,ios,$(arch)))
mac_config_names_all = $(foreach arch, $(mac_archs_all), $(call make_config_name,mac,$(arch)))
config_names_all = $(ios_config_names_all) $(mac_config_names_all)

index = $(words $(shell a="$(2)";echo $${a/$(1)*/$(1)} ))
swap  = $(word $(call index,$(1),$(2)),$(3))
normalize = $(foreach x,$(1),$(x))
eq = $(and $(findstring $(1), $(2)), $(findstring $(2), $(1)))

get_sdk = $(call swap, $(1), $(config_names_all), $(sdks))
get_arch = $(call swap, $(1), $(config_names_all), $(archs_all))
get_host_name = $(call swap, $(1), $(config_names_all), $(host_names_all))
get_min_version = $(call swap, $(1), $(config_names_all), $(min_versions_all))
get_platform = $(firstword $(subst -, ,$1))
get_config = $(call normalize, $(foreach config, $(config_names_all), $(if $(findstring /$(config)/,$(1)),$(config),)))
get_platform_of_folder = $(call get_platform, $(call get_config, $(1)))
filter_by_platform = $(call normalize, $(foreach folder, $(2), $(if $(call eq, $(call get_platform_of_folder, $(folder)), $(1)), $(folder),)))

IOS_ARCHS ?= $(ios_archs_all)
MAC_ARCHS ?= $(mac_archs_all)
ios_config_names = $(foreach arch, $(IOS_ARCHS), $(call swap, $(arch), $(ios_archs_all), $(ios_config_names_all) ) )
mac_config_names = $(foreach arch, $(MAC_ARCHS), $(call swap, $(arch), $(mac_archs_all), $(mac_config_names_all) ) )
config_names = $(foreach platform, $(PLATFORMS), $($(platform)_config_names))
