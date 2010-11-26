
CC=avr-gcc
AS=avr-as
LDFLAGS=-mmcu=atmega32u4 -nostdlib
ASFLAGS=-mmcu=atmega32u4

all: picfavr.bin picfavr.hex

picfavr.bin: picfavr
	avr-objcopy -O binary $< $@

picfavr.hex: picfavr
	avr-objcopy -O ihex $< $@

picfavr: picfavr.o


upload: picfavr.hex
	../emu/teensy-usb/teensy_loader_cli/teensy_loader_cli -mmcu=atmega32u4 picfavr.hex

