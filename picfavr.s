
.equ	SREG,0x3f
.equ	SPL,0x3d
.equ	SPH,0x3e

.equ	UENUM,0x00e9
.equ	UECONX,0x00eb 
.equ	UECFG0X,0x00ec
.equ	UECFG1X,0x00ed
.equ	UEIENX,0x00f0
.equ	UEINTX,0x00e8
.equ	UEDATX,0x00f1

.equ	STALLRQ,5
.equ	EPEN,0

.equ	RXSTPI,3
.equ	RXOUTI,2
.equ	TXINI,0

.equ	GET_STATUS,0x00
.equ	SET_ADDRESS,0x05
.equ	GET_DESCRIPTOR,0x06
.equ	GET_CONFIGURATION,0x08
.equ	SET_CONFIGURATION,0x09

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

wait:	rjmp wait

go:
	eor     r16,r16
	out     SREG,r16
	ldi     r16,0xFF
	out     SPL,r16
	ldi     r16,0x0A
	out     SPH,r16


ep0conf:
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

waitrcv:
	lds	r16,UEINTX
	sbrc	r16,RXSTPI
	rcall	control
	rjmp	waitrcv

control:
	lds	r16,UEDATX ; bmRequestType
	lds	r16,UEDATX ; bRequest

	cpi	r16,GET_STATUS
	breq	Ugetstatus
	cpi	r16,GET_DESCRIPTOR
	breq	Ugetdescriptor

	rcall	stall
	ret

stall:
	ldi	r16,(1<<STALLRQ)|(1<<EPEN)
	sts	UECONX,r16
	ret

setupack:
	ldi	r16,~(1<<RXSTPI)
	sts	UEINTX,r16
	ldi	r16,~(1<<TXINI)
	sts	UEINTX,r16
	ret


waitin:
	lds	r16,UEINTX
	sbrs	r16,TXINI
	rjmp	waitin
	ret

Ugetdescriptor:
	lds	r16,UEDATX ; wValue (lo)
	lds	r17,UEDATX ; wValue (hi), discard
	
	lds	r17,UEDATX ; wIndex (lo), discard
	lds	r17,UEDATX ; wIndex (hi), discard
	
	lds	r17,UEDATX ; wLength (lo)
	lds	r18,UEDATX ; wLength (hi)

	mov	r16,r0
	rcall	setupack
	rcall	waitin
	mov	r0,r16

	cpi	r16,0x01
	breq	devdescr

	rcall	stall
	ret

devdescr
	



Ugetstatus:
	rcall	setupack
	rcall	waitin

	clr	r16
	sts	UEDATX,r16
	sts	UEDATX,r16
	ldi	r16,~(1<<TXINI)
	sts	UEINTX,r16

Ugetstatus.out:
	lds	r16,UEINTX
	sbrs	r16,RXOUTI
	rjmp	Ugetstatus.out
	ldi	r16,~(1<<RXOUTI)
	sts	UEINTX,r16

	ret


Iusbgen:
	push	r16
	in      r16, 0x3f
	push	r16

	lds     r16,0x00E1
	sbrc	r16,3
	rjmp	usbreset

	pop	r16
	out     0x3f, r16
	pop	r16
	reti

usbreset:

;	we really reset everything
	sei
	rjmp	go

