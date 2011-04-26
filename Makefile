
CC=avr-gcc
AS=avr-as
LDFLAGS=-mmcu=atmega32u4 -nostdlib
ASFLAGS=-mmcu=atmega32u4

all: cliavr.bin cliavr.hex cli

cliavr.bin: cliavr
	avr-objcopy -O binary $< $@

cliavr.hex: cliavr
	avr-objcopy -O ihex $< $@

cliavr: cliavr.o


upload: cliavr.hex
	../emu/teensy-usb/teensy_loader_cli/teensy_loader_cli -mmcu=atmega32u4 cliavr.hex

libcliavr.so: libcliavr.c
	gcc -c -fPIC libcliavr.c -o libcliavr.o
	gcc -shared -Wl,-soname,libcliavr.so -o libcliavr.so libcliavr.o -lusb


cli: cli.c libcliavr.so
	gcc -o cli cli.c -L. -lcliavr

