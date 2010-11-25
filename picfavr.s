
.equ	UENUM,0x00e9
.equ	UECONX,0x00eb 
.equ	UECFG0X,0x00ec
.equ	UECFG1X,0x00ed
.equ	UEIENX,0x00f0

Ireset:	rjmp	start
	nop
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	rjmp Iusbgen
	nop
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti

start:
clc16mhz:
	ldi     r16,0x80
	eor     r0,r0
	sts     0x0061,r16
	sts     0x0061,r0

usbpad:
	ldi     r16,0x01
	sts     0x00D7,r16

usbenable:
	ldi     r16,0xA0
	sts     0x00D8,r16

usbpll:
	ldi	r16,0b10010
	out     0x29,r16

waitpll:
	in	r16,0x29
	sbrs	r16,0
	rjmp	waitpll

usbrun:
	ldi     r16,0b10000000
	sts     0x00D8,r16

usbconf:
	eor	r0,r0
	sts	0x00E0,r0

usbintrs:
	ldi     r16,0b1000
	sts     0x00E2,r16
	sei

loop:
	jmp loop


Iusbgen:
	push	r16
	in      r16, 0x3f
	push	r16

	lds     r16,0x00E1
	sbrc	r16,3
	rjmp	usbreset

usbreset.ret:
	pop	r16
	out     0x3f, r16
	pop	r16
	reti

usbreset:
	eor	r16,r16
	sts	UENUM,r16
	ldi	r16,0b1
	sts	UECONX,r16
	eor	r16,r16
	sts	UECFG0X,r16
	ldi	r16,0b10
	sts	UECFG1X,r16
	eor	r16,r16
	sts	UEIENX,r16
	rjmp	usbreset.ret



