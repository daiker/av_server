# Makefile Version 4.0
# depend on daiker install directory.
# depend on 3rd lua/jemalloc lib.
# ============================================================================
# Copyright (c) Moonlight Daiker Inc 2016
#
# Use of this software is controlled by the terms and conditions found in the
# license agreement under which this software has been supplied or provided.
# ============================================================================

ifndef chip
$(error target type has not found)
endif

ifeq ($(chip),arm)
CROSS_COMPILE=arm-hisiv100nptl-linux-
else ifeq ($(chip),x86)
CROSS_COMPILE=
else
$(error target type has not support)
endif


DAIKER_PATH=../..

#include $(DAIKER_INSTALL_DIR)
include $(DAIKER_PATH)/m/Rule.make
TARGET = ./bin/$(chip)/$(notdir $(CURDIR))
# Comment this out if you want to see full compiler and linker output.
VERBOSE = @

DAIKER_LIB=$(DAIKER_INSTALL_DIR)/l/libdaiker.a
INCLUDE_PATH=-I$(DAIKER_INSTALL_DIR)/h


CC=$(CROSS_COMPILE)gcc
AR=$(CROSS_COMPILE)ar

# lua
LUA_STATICLIB := 3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= 3rd/lua

# jemalloc 
JEMALLOC_STATICLIB := 3rd/jemalloc/lib/libjemalloc_pic.a
JEMALLOC_INC := 3rd/jemalloc/include/jemalloc
MALLOC_STATICLIB := $(JEMALLOC_STATICLIB)	
	

C_FLAGS += -Wall -g -O2 -I$(LUA_INC) -I$(JEMALLOC_INC) $(MYCFLAGS)
LD_FLAGS += -pthread 

COMPILE.c = $(VERBOSE) $(CC) $(C_FLAGS) -c
LINK.c = $(VERBOSE) $(CC) $(LD_FLAGS)

SOURCES = $(wildcard *.c) $(wildcard ../*.c) $(wildcard src/*.c)
HEADERS = $(wildcard *.h) $(wildcard ../*.h) $(wildcard inc/*.h)

OBJFILES = $(SOURCES:%.c=%.o)

.PHONY : all jemalloc update3rd

all :	$(TARGET)

$(TARGET): $(DAIKER_LIB) $(LUA_LIB) $(MALLOC_STATICLIB) $(OBJFILES)
	@echo Linking $@ from $^..
	$(LINK.c) $(INCLUDE_PATH)  -o $@ $^

	@#./qc 192.168.1.100 encode_rtp /tmp/app/encode_rtp
$(OBJFILES):	%.o: %.c $(HEADERS) $(XDC_CFLAGS)
	@echo Compiling $@ from $<..
	$(COMPILE.c) $(INCLUDE_PATH) -o $@ $<

$(XDC_LFILE) $(XDC_CFLAGS):	$(XDC_CFGFILE)
	@echo
	@echo ======== Building $(TARGET) ========
	@echo Configuring application using $<
	@echo
	$(VERBOSE) XDCPATH="$(XDC_PATH)" $(CONFIGURO) -c $(MVTOOL_DIR) -o $(XDC_CFG) -t $(XDC_TARGET) -p $(XDC_PLATFORM) $(XDC_CFGFILE)


$(LUA_STATICLIB) :
	cd 3rd/lua && $(MAKE) CC='$(CC) -std=gnu99' linux

$(JEMALLOC_STATICLIB) : 3rd/jemalloc/Makefile
	cd 3rd/jemalloc && $(MAKE) CC=$(CC) 

3rd/jemalloc/autogen.sh :
	git submodule update --init
3rd/jemalloc/Makefile : | 3rd/jemalloc/autogen.sh
	cd 3rd/jemalloc && ./autogen.sh --with-jemalloc-prefix=je_ --disable-valgrind
jemalloc : $(MALLOC_STATICLIB)

update3rd :
	rm -rf 3rd/jemalloc && git submodule update --init	
	
	
clean:
	$(VERBOSE) -$(RM) -rf  $(OBJFILES) $(TARGET) *~ *.d .dep

cleanall: clean
ifneq (,$(wildcard 3rd/jemalloc/Makefile))
	cd 3rd/jemalloc && $(MAKE) clean
endif
	cd 3rd/lua && $(MAKE) clean
	rm -f $(LUA_STATICLIB)
