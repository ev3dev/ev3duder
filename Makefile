##################################################
# Cross-Platform Makefile for the ev3duder utility
#
# Ahmad Fatoum
# Hochschule Aschaffenburg
# 2015-06-17
##################################################

BIN_NAME = ev3duder	
VERSION = 0.3.0
# tip: CC=clang FLAGS=-Weverything shows all GNU extensions
FLAGS += -std=c99 -Wall -Wextra -DVERSION='"$(VERSION)"'
SRCDIR = src
OBJDIR = build

SRCS = src/main.c src/packets.c src/run.c src/info.c src/up.c src/ls.c src/rm.c src/mkdir.c src/mkrbf.c src/dl.c src/listen.c src/send.c

INC += -Ihidapi/hidapi/
 
####################
CREATE_BUILD_DIR := $(shell mkdir build 2>&1)
ifeq ($(OS),Windows_NT)

## No rm?
ifneq (, $(shell where rm 2>NUL)) 
RM = del /Q
# Powershell, cygwin and msys all provide rm(1)
endif

## Win32
ifneq ($(MAKECMDGOALS),cross)
FLAGS += -DCONFIGURATION='"HIDAPI/hid.dll"' -DSYSTEM="Windows"
# TODO: remove all %zu prints altogether?
FLAGS += -Wno-unused-value -D__USE_MINGW_ANSI_STDIO=1
SRCS += src/bt-win.c
HIDSRC += hidapi/windows/hid.c
LDFLAGS += -mwindows -lsetupapi -municode 
BIN_NAME := $(addsuffix .exe, $(BIN_NAME))
# CodeSourcery prefix
endif
CROSS_PREFIX = arm-none-linux-gnueabi-g
else
UNAME = $(shell uname -s)

## Linux
ifeq ($(UNAME),Linux)
FLAGS += -DCONFIGURATION='"HIDAPI/libusb-1.0"' -DSYSTEM='"Linux"'
HIDSRC += hidapi/libusb/hid.c
HIDFLAGS += `pkg-config libusb-1.0 --cflags`
LDFLAGS += `pkg-config libusb-1.0 --libs` -lrt -lpthread
INSTALL = $(shell sh udev.sh)
# Linaro prefix
CROSS_PREFIX = arm-linux-gnueabi-g
endif

## OS X
ifeq ($(UNAME),Darwin)
ifneq ($(MAKECMDGOALS),cross)
FLAGS += -DCONFIGURATION='"HIDAPI/IOHidManager"' -DSYSTEM='"OS X"'
HIDSRC += hidapi/mac/hid.c
LDFLAGS += -framework IOKit -framework CoreFoundation
# minot prefix
endif
CROSS_PREFIX = arm-none-linux-gnueabi-g
endif

## BSD
ifeq ($(findstring BSD, $(UNAME)), BSD)
ifneq ($(MAKECMDGOALS),cross)
FLAGS += -DCONFIGURATION='"HIDAPI/libusb-1.0"' -DSYSTEM='"BSD"'
HIDSRC += hidapi/libusb/hid.c
LDFLAGS += -L/usr/local/lib -lusb -liconv -pthread
INC += -I/usr/local/include
endif
endif

## ALL UNICES
SRCS += src/bt-unix.c
SRCS += src/tcp-unix.c
SRCS += src/tunnel.c
endif

CROSS_PREFIX ?= arm-linux-gnueabi-g

OBJS = $(SRCS:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

.DEFAULT: all
all: $(BIN_NAME)

$(BIN_NAME): $(OBJS) $(OBJDIR)/hid.o
	$(PREFIX)$(CC) $(OBJS) $(OBJDIR)/hid.o $(LDFLAGS) $(LIBS) -o $(BIN_NAME)

# static enables valgrind to act better -DDEBUG!
$(OBJS): $(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(PREFIX)$(CC) -c $< -MMD $(FLAGS) $(INC) -o $@
-include $(OBJDIR)/*.d

$(OBJDIR)/hid.o: $(HIDSRC)
	$(PREFIX)$(CC) -c $< -o $@ $(INC) $(HIDFLAGS)


debug: FLAGS += -g
debug: LIBS := $(LIBS)
debug: LIBS += 
debug: $(BIN_NAME)

cross: PREFIX ?= $(CROSS_PREFIX)
cross: FLAGS += -DCONFIGURATION='"HIDAPI/libusb-1.0"' -DSYSTEM='"Linux"'
cross: HIDSRC += hidapi/libusb/hid.c
cross: HIDFLAGS += `pkg-config libusb-1.0 --cflags`
cross: LDFLAGS += `pkg-config libusb-1.0 --libs` -lrt -lpthread
cross: $(BIN_NAME)

# linux only for now, installs udev rules, for rootless access to ev3
.PHONY: install
<<<<<<< HEAD
install: $(BIN_NAME) ev3-udev.rules udev.sh
	ifneq ($(OS),Windows_NT)
	-@mkdir /usr/lib/ev3duder/
	cp $(BIN_NAME) /usr/lib/ev3duder
	ln -s /usr/lib/ev3duder/$(BIN_NAME) /usr/bin/ev3
	$(INSTALL)
	endif
.PHONY: clean
clean:
	$(RM) $(BIN_NAME) && cd $(OBJDIR) && $(RM) *.o *.d 

