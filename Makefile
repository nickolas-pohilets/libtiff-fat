PNG_NAME        := libpng-1.6.26
JPEG_SRC_NAME   := jpegsrc.v9a# filename at the server
JPEG_DIR_NAME   := jpeg-9a# folder name after the JPEG_SRC_NAME archive has been unpacked
TIFF_NAME       := tiff-4.0.6

include Common.make

IMAGE_SRC = $(shell pwd)
PNG_SRC   = $(IMAGE_SRC)/$(PNG_NAME)
JPEG_SRC = $(IMAGE_SRC)/$(JPEG_DIR_NAME)
TIFF_SRC = $(IMAGE_SRC)/$(TIFF_NAME)

IMAGE_LIB_DIR = $(shell pwd)/dependencies/lib/
IMAGE_INC_DIR = $(shell pwd)/dependencies/include/

libpngfiles = libpng.a
libjpegfiles = libjpeg.a
libtifffiles = libtiff.a libtiffxx.a

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
