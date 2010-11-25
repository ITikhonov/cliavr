
CC=avr-gcc
LDFLAGS=-mmcu=atmega32u4 -nostdlib

picfavr.bin: picfavr
	avr-objcopy -O binary $< $@

