#
# Makefile.180 for Arduino/AVR 
#
#  Note:
#  	Display list make database: make -p -f/dev/null | less


# Install path of the arduino software. Requires a '/' at the end.
ARDUINO_PATH:=/home/kraus/prg/arduino-1.8.0/

# Board (and prozessor) information: see $(ARDUINO_PATH)hardware/arduino/avr/boards.txt
# Some examples:
#	BOARD		DESCRIPTION
#	uno			Arduino Uno
#	atmega328	Arduino Duemilanove or Nano w/ ATmega328
#	diecimila		Arduino Diecimila, Duemilanove, or Nano w/ ATmega168
#	mega		Arduino Mega
#	mega2560	Arduino Mega2560
#	mini			Arduino Mini
#	lilypad328	LilyPad Arduino w/ ATmega328  
BOARD:=uno

SRC_DIRS=$(ARDUINO_PATH)hardware/arduino/avr/cores/arduino/
SRC_DIRS+=$(ARDUINO_PATH)hardware/arduino/avr/libraries/SPI/src/
SRC_DIRS+=$(ARDUINO_PATH)hardware/arduino/avr/libraries/SPI/src/utility/
SRC_DIRS+=$(ARDUINO_PATH)hardware/arduino/avr/libraries/Wire/src/
SRC_DIRS+=$(ARDUINO_PATH)hardware/arduino/avr/libraries/Wire/src/utility/
SRC_DIRS+=../../../../csrc/
SRC_DIRS+=../../../../cppsrc/

#=== suffixes ===
.SUFFIXES: .elf .hex .ino

#=== identify user files ===
INOSRC:=$(shell ls *.ino)
TARGETNAME=$(basename $(INOSRC))

#=== internal names ===
LIBNAME:=$(TARGETNAME).a
ELFNAME:=$(TARGETNAME).elf
HEXNAME:=$(TARGETNAME).hex
BINNAME:=$(TARGETNAME).bin
DISNAME:=$(TARGETNAME).dis
MAPNAME:=$(TARGETNAME).map

#=== replace standard tools ===
CC:=$(ARDUINO_PATH)hardware/tools/avr/bin/avr-gcc
CXX:=$(ARDUINO_PATH)hardware/tools/avr/bin/avr-g++
AR:=$(ARDUINO_PATH)hardware/tools/avr/bin/avr-gcc-ar
OBJCOPY:=$(ARDUINO_PATH)hardware/tools/avr/bin/avr-objcopy
OBJDUMP:=$(ARDUINO_PATH)hardware/tools/avr/bin/avr-objdump
SIZE:=$(ARDUINO_PATH)hardware/tools/avr/bin/avr-size

#=== get values from boards.txt ===
BOARDS_TXT:=$(ARDUINO_PATH)hardware/arduino/avr/boards.txt

# get the MCU value from the $(BOARD).build.mcu variable. For the atmega328 board this is atmega328p
MCU:=$(shell sed -n -e "s/$(BOARD).build.mcu=\(.*\)/\1/p" $(BOARDS_TXT))
# get the F_CPU value from the $(BOARD).build.f_cpu variable. For the atmega328 board this is 16000000
F_CPU:=$(shell sed -n -e "s/$(BOARD).build.f_cpu=\(.*\)/\1/p" $(BOARDS_TXT))
# get variant subfolder
VARIANT:=$(shell sed -n -e "s/$(BOARD).build.variant=\(.*\)/\1/p" $(BOARDS_TXT))
UPLOAD_SPEED:=$(shell sed -n -e "s/$(BOARD).upload.speed=\(.*\)/\1/p" $(BOARDS_TXT))
# get the AVRDUDE_PROGRAMMER value from the $(BOARD).upload.protocol variable. For the atmega328 board this is stk500
UPLOAD_PROTOCOL:=$(shell sed -n -e "s/$(BOARD).upload.protocol=\(.*\)/\1/p" $(BOARDS_TXT))
# use stk500v1, because stk500 will default to stk500v2
#AVRDUDE_PROGRAMMER:=stk500v1

#=== get all include dirs ===
INC_DIRS:=. $(SRC_DIRS) $(ARDUINO_PATH)hardware/arduino/avr/variants/$(VARIANT)
INC_OPTS:=$(addprefix -I,$(INC_DIRS))

#=== get all source files ===
CSRC:=$(shell ls $(addsuffix *.c,$(SRC_DIRS)) 2>/dev/null) 
CPPSRC:=$(shell ls $(addsuffix *.cpp,$(SRC_DIRS)) 2>/dev/null)

#=== get all obj files ===
COBJ:=$(CSRC:.c=.o)
CPPOBJ:=$(CPPSRC:.cpp=.o)
OBJ:=$(COBJ) $(CPPOBJ) $(TARGETNAME).o


#=== options ===

COMMON_FLAGS = -Os -DF_CPU=$(F_CPU) -mmcu=$(MCU) 
COMMON_FLAGS +=-DARDUINO=10800 -DARDUINO_AVR_UNO -DARDUINO_ARCH_AVR
COMMON_FLAGS +=-ffunction-sections -fdata-sections -MMD -flto -fno-fat-lto-objects
COMMON_FLAGS +=$(INC_OPTS)
CFLAGS:=$(COMMON_FLAGS)
CXXFLAGS:=$(COMMON_FLAGS)
LDFLAGS:=-Os -g -flto -fuse-linker-plugin -Wl,--gc-sections -mmcu=$(MCU)
LDLIBS:=-lm

all: $(HEXNAME) $(DISNAME)
	$(SIZE) $(ELFNAME)

debug: 
	@echo $(MCU) $(F_CPU) $(VARIANT) $(UPLOAD_SPEED) $(UPLOAD_PROTOCOL)
	@echo $(SRC_DIRS)
	@echo $(CSRC)
	@echo $(CPPSRC)
	@echo $(INC_OPTS)

clean:
	$(RM) $(OBJ) $(HEXNAME) $(ELFNAME) $(LIBNAME) $(DISNAME) $(MAPNAME) $(BINNAME)

# implicit rules
.ino.cpp:
	@cp $< $@
	
.elf.hex:
	@$(OBJCOPY) -O ihex -R .eeprom $< $@

# explicit rules
$(ELFNAME): $(LIBNAME)($(OBJ)) 
	$(LINK.o) $(LFLAGS) $(LIBNAME) $(LDLIBS) -o $@

$(DISNAME): $(ELFNAME)
	$(OBJDUMP) -D -S $< > $@

	
