PNG_NAME        := libpng-1.6.26
JPEG_SRC_NAME   := jpegsrc.v9a# filename at the server
JPEG_DIR_NAME   := jpeg-9a# folder name after the JPEG_SRC_NAME archive has been unpacked
TIFF_NAME       := tiff-4.0.6

SDK_IPHONEOS_PATH=$(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR_PATH=$(shell xcrun --sdk iphonesimulator --show-sdk-path)
SDK_MACOSX_PATH=$(shell xcrun --sdk macosx --show-sdk-path)
XCODE_DEVELOPER_PATH="`xcode-select -p`"
XCODETOOLCHAIN_PATH=$(XCODE_DEVELOPER_PATH)/Toolchains/XcodeDefault.xctoolchain
IOS_DEPLOY_TGT="7.0"
MAC_DEPLOY_TGT="10.10"

IMAGE_SRC = $(shell pwd)
PNG_SRC   = $(IMAGE_SRC)/$(PNG_NAME)
JPEG_SRC = $(IMAGE_SRC)/$(JPEG_DIR_NAME)
TIFF_SRC = $(IMAGE_SRC)/$(TIFF_NAME)

IMAGE_LIB_DIR = $(shell pwd)/dependencies/lib/
IMAGE_INC_DIR = $(shell pwd)/dependencies/include/

libpngfiles = libpng.a
libjpegfiles = libjpeg.a
libtifffiles = libtiff.a libtiffxx.a

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

libpngfolders  = $(foreach config, $(config_names), $(PNG_SRC)/$(config)/)
libjpegfolders = $(foreach config, $(config_names), $(JPEG_SRC)/$(config)/)
libtifffolders = $(foreach config, $(config_names), $(TIFF_SRC)/$(config)/)

libpngfolders_all  = $(foreach config, $(config_names_all), $(PNG_SRC)/$(config)/)
libjpegfolders_all = $(foreach config, $(config_names_all), $(JPEG_SRC)/$(config)/)
libtifffolders_all = $(foreach config, $(config_names_all), $(TIFF_SRC)/$(config)/)

libpngmakefile  = $(foreach folder, $(libpngfolders), $(addprefix $(folder), Makefile) )
libjpegmakefile = $(foreach folder, $(libjpegfolders), $(addprefix $(folder), Makefile) )
libtiffmakefile = $(foreach folder, $(libtifffolders), $(addprefix $(folder), Makefile) )

get_fat = $(foreach platform, $(PLATFORMS), $(addprefix $(IMAGE_LIB_DIR)$(platform)/, $(1)))
libpngfat  = $(call get_fat, $(libpngfiles))
libjpegfat = $(call get_fat, $(libjpegfiles))
libtifffat = $(call get_fat, $(libtifffiles))

libpng     = $(foreach folder, $(libpngfolders), $(addprefix $(folder)/lib/, $(libpngfiles)) )
libjpeg    = $(foreach folder, $(libjpegfolders), $(addprefix $(folder)/lib/, $(libjpegfiles)) )
libtiff    = $(foreach folder, $(libtifffolders), $(addprefix $(folder)/lib/, $(libtifffiles)) )

libpngconfig  = $(PNG_SRC)/configure
libjpegconfig = $(JPEG_SRC)/configure
libtiffconfig = $(TIFF_SRC)/configure

dependant_libs = libpng libjpeg libtiff

.PHONY : all
all : $(dependant_libs)

#######################
# Build libtiff and all of it's dependencies
#######################
libtiff : $(libtifffat)

$(libtifffat) : $(libtiff)
	mkdir -p $(@D)
	$(eval p = $(notdir $(@D)))
	$(eval p_folders = $(call filter_by_platform, $(p), $(libtifffolders_all)))
	xcrun lipo $(realpath $(addsuffix lib/$(@F), $(p_folders)) ) -create -output $@
	mkdir -p $(IMAGE_INC_DIR)
	cp -rvf $(firstword $(libtifffolders))/include/*.h $(IMAGE_INC_DIR)

$(libtiff) :  $(libtiffmakefile)
	cd $(abspath $(@D)/..) ; \
	$(MAKE) -sj8 && $(MAKE) install

$(TIFF_SRC)/%/Makefile : $(libtiffconfig)
	export SDKROOT="$(call get_sdk, $*)" ; \
	export CFLAGS="-Qunused-arguments -arch $(call get_arch, $*) -pipe -no-cpp-precomp -isysroot $$SDKROOT $(call get_min_version, $*) -O2 -fembed-bitcode" ; \
	export CPPFLAGS=$$CFLAGS ; \
	export CXXFLAGS="$$CFLAGS -Wno-deprecated-register"; \
	mkdir -p $(@D) ; \
	cd $(@D) ; \
	../configure --host=$(call get_host_name, $*) --enable-fast-install --enable-shared=no --prefix=`pwd` --without-x --with-jpeg-include-dir=$(abspath $(@D)/../../$(JPEG_DIR_NAME)/$*/include) --with-jpeg-lib-dir=$(abspath $(@D)/../../$(JPEG_DIR_NAME)/$*/lib)

libpng : $(libpngfat)

$(libpngfat) : $(libpng)
	mkdir -p $(@D)
	$(eval p = $(notdir $(@D)))
	$(eval p_folders = $(call filter_by_platform, $(p), $(libpngfolders_all)))
	xcrun lipo $(realpath $(addsuffix lib/$(@F), $(p_folders)) ) -create -output $@
	mkdir -p $(IMAGE_INC_DIR)
	cp -rvf $(firstword $(libpngfolders))/include/*.h $(IMAGE_INC_DIR)

$(libpng) : $(libpngmakefile)
	cd $(abspath $(@D)/..) ; \
	$(MAKE) -sj8 && $(MAKE) install

$(PNG_SRC)/%/Makefile : $(libpngconfig)
	export SDKROOT="$(call get_sdk, $*)" ; \
	export CFLAGS="-Qunused-arguments -arch $(call get_arch, $*) -pipe -no-cpp-precomp -isysroot $$SDKROOT $(call get_min_version, $*) -O2 -fembed-bitcode" ; \
	export CPPFLAGS=$$CFLAGS ; \
	export CXXFLAGS="$$CFLAGS -Wno-deprecated-register"; \
	echo $$CFLAGS; \
	mkdir -p $(@D) ; \
	cd $(@D) ; \
	../configure --host=$(call get_host_name, $*) --enable-shared=no --prefix=`pwd`

libjpeg : $(libjpegfat)

$(libjpegfat) : $(libjpeg)
	mkdir -p $(@D)
	$(eval p = $(notdir $(@D)))
	$(eval p_folders = $(call filter_by_platform, $(p), $(libjpegfolders_all)))
	xcrun lipo $(realpath $(addsuffix lib/$(@F), $(p_folders)) ) -create -output $@
	mkdir -p $(IMAGE_INC_DIR)
	cp -rvf $(firstword $(libjpegfolders))/include/*.h $(IMAGE_INC_DIR)

$(libjpeg) : $(libjpegmakefile)
	cd $(abspath $(@D)/..) ; \
	$(MAKE) -sj8 && $(MAKE) install

$(JPEG_SRC)/%/Makefile : $(libjpegconfig)
	export SDKROOT="$(call get_sdk, $*)" ; \
	export CFLAGS="-Qunused-arguments -arch $(call get_arch, $*) -pipe -no-cpp-precomp -isysroot $$SDKROOT $(call get_min_version, $*) -O2 -fembed-bitcode" ; \
	export CPPFLAGS=$$CFLAGS ; \
	export CXXFLAGS="$$CFLAGS -Wno-deprecated-register"; \
	mkdir -p $(@D) ; \
	cd $(@D) ; \
	../configure --host=$(call get_host_name, $*) --enable-shared=no --prefix=`pwd`

#######################
# Download sources
#######################
$(libtiffconfig) :
	curl ftp://downloads.osgeo.org/pub/libtiff/$(TIFF_NAME).tar.gz | tar -xpf-

$(libjpegconfig) :
	curl http://www.ijg.org/files/$(JPEG_SRC_NAME).tar.gz | tar -xpf-

$(libpngconfig) :
	curl ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/$(PNG_NAME).tar.gz | tar -xpf-

#######################
# Clean
#######################
.PHONY : clean
clean : cleanpng cleantiff cleanjpeg

.PHONY : cleanpng
cleanpng :
	for folder in $(realpath $(libpngfolders_all) ); do \
        cd $$folder; \
        $(MAKE) clean; \
	done

.PHONY : cleanjpeg
cleanjpeg :
	for folder in $(realpath $(libjpegfolders_all) ); do \
        cd $$folder; \
        $(MAKE) clean; \
	done

.PHONY : cleantiff
cleantiff :
	for folder in $(realpath $(libtifffolders_all) ); do \
        cd $$folder; \
        $(MAKE) clean; \
    done

.PHONY : mostlyclean
mostlyclean : mostlycleanpng mostlycleantiff mostlycleanjpeg

.PHONY : mostlycleanpng
mostlycleanpng :
	for folder in $(realpath $(libpngfolders) ); do \
        cd $$folder; \
        $(MAKE) mostlyclean; \
    done

.PHONY : mostlycleantiff
mostlycleantiff :
	for folder in $(realpath $(libtifffolders_all) ); do \
        cd $$folder; \
        $(MAKE) mostlyclean; \
	done

.PHONY : mostlycleanjpeg
mostlycleanjpeg :
	for folder in $(realpath $(libjpegfolders_all) ); do \
        cd $$folder; \
        $(MAKE) mostlyclean; \
    done

.PHONY : distclean
distclean :
	-rm -rf $(IMAGE_LIB_DIR)
	-rm -rf $(IMAGE_INC_DIR)
	-rm -rf $(PNG_SRC)
	-rm -rf $(JPEG_SRC)
	-rm -rf $(TIFF_SRC)
