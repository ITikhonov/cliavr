
CC=avr-gcc
AS=avr-as
LDFLAGS=-mmcu=atmega32u4 -nostdlib
ASFLAGS=-mmcu=atmega32u4

picfavr.bin: picfavr
	avr-objcopy -O binary $< $@

picfavr: picfavr.o
