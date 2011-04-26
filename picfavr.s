;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.macro LIGHT
	sbi     0x0b, 6
.endm

.equ	SREG,0x3f
.equ	SPL,0x3d
.equ	SPH,0x3e

.equ	CLKPR,0x0061

.equ	UDCON,0x00e0
.equ	UHWCON,0x00d7
.equ	USBCON,0x00d8
.equ	UENUM,0x00e9
.equ	UECONX,0x00eb 
.equ	UECFG0X,0x00ec
.equ	UECFG1X,0x00ed
.equ	UEIENX,0x00f0
.equ	UEINTX,0x00e8
.equ	UEDATX,0x00f1
.equ	UDADDR,0x00e3
.equ	UDIEN,0x00e2
.equ	UDINT,0x00e1

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

devdescr_data:
	.byte        18			; bLength
	.byte        1			; bDescriptorType
	.byte        0x00, 0x02		; bcdUSB
	.byte        0			; bDeviceClass
	.byte        0			; bDeviceSubClass
	.byte        0			; bDeviceProtocol
	.byte        32			; bMaxPacketSize0
	.byte        0xC0,0x16		; idVendor
	.byte        0x80,0x04		; idProduct
	.byte        0x00, 0x01		; bcdDevice
	.byte        0			; iManufacturer
	.byte        0			; iProduct
	.byte        0			; iSerialNumber
	.byte        1			; bNumConfigurations


confdescr_data:
	.byte	9	; bLength
	.byte	2	; bDescriptorType
	.byte	18,0	; wTotalLength
	.byte	1	; bNumInterfaces
	.byte	1	; bConfigurationValue
	.byte	0	; iConfiguration
	.byte	0b10000000	; bmAttributes
	.byte	50	; bMaxPower
interfacedesc.data:
	.byte 9		; bLength
	.byte 4		; bDescriptorType
	.byte 0		; bInterfaceNumber
	.byte 0		; bAlternateSetting
	.byte 0		; bNumEndpoints
	.byte 0xff	; bInterfaceClass
	.byte 0x00	; bInterfaceSubClass
	.byte 0x00	; bInterfaceProtocol
	.byte 0		; iInterface

.align 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hardware Setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start:
clc16mhz:
	ldi     r16,0x80
	sts     CLKPR,r16
	clr     r0
	sts     CLKPR,r0

usbpad:
	ldi     r16,0x01
	sts     UHWCON,r16

usbenable:
	ldi     r16,0b10100000
	sts     USBCON,r16

usbpll:
	ldi	r16,0b10010
	out     0x29,r16

waitpll:
	in	r16,0x29
	sbrs	r16,0
	rjmp	waitpll

usbrun:
	ldi     r16,0b10010000
	sts     USBCON,r16

usbintrs:
	ldi     r16,0b1000
	sts     UDIEN,r16
	sei

usbconf:
	clr	r0
	sts	UDCON,r0

wait:
	rjmp wait



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Partial reset and main loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

go:
	clr     r16
	out     SREG,r16
	ldi     r16,0xFF
	out     SPL,r16
	ldi     r16,0x0A
	out     SPH,r16

ep0conf:
	clr	r16
	sts	UENUM,r16
	ldi	r16,0b1
	sts	UECONX,r16
	eor	r16,r16
	sts	UECFG0X,r16
	ldi	r16,0b0110010
	sts	UECFG1X,r16
	eor	r16,r16
	sts	UEIENX,r16

	sei

waitrcv:
	lds	r16,UEINTX
	sbrc	r16,RXSTPI
	rcall	pktsetup
	rjmp	waitrcv

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Commons
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stall:
	ldi	r16,(1<<STALLRQ)|(1<<EPEN)
	sts	UECONX,r16
	ret

setupack:
	ldi	r16,~((1<<RXSTPI)|(1<<TXINI)|(1<RXOUTI))
	sts	UEINTX,r16
	ret

sendin:
	ldi	r16,~(1<<TXINI)
	sts	UEINTX,r16
	ret

waitin:
	lds	r16,UEINTX
	sbrs	r16,TXINI
	rjmp	waitin
	ret

; r16 - len have, r17:r18 - len ordered
; return r16 - min(r16,r17:r18)
pktlen:
	cpi r18,0
	brne pktlen.r16
	cp r16,r17
	brlo pktlen.r16
	mov r16,r17
	ret

pktlen.r16:
	ret


waitout:
	lds	r16,UEINTX
	sbrs	r16,RXOUTI
	rjmp	waitout
	ldi	r16,~(1<<RXOUTI)
	sts	UEINTX,r16
	ret

writeblock:
	lpm	r17,Z+
	sts	UEDATX,r17
	dec	r16
	brne	writeblock
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pktsetup:
	lds	r16,UEDATX ; bmRequestType
	lds	r16,UEDATX ; bRequest

	cpi	r16,GET_STATUS
	breq	Ugetstatus_
	cpi	r16,GET_DESCRIPTOR
	breq	Ugetdescriptor_
	cpi	r16,SET_ADDRESS
	breq	Usetaddress_
	cpi	r16,SET_CONFIGURATION
	breq	Usetconfiguration_
	cpi	r16,0xf0
	breq	Ureadmem_
	cpi	r16,0xf1
	breq	Uwritemem_

	rcall	stall
	ret

Ugetstatus_: rjmp Ugetstatus
Ugetdescriptor_: rjmp Ugetdescriptor
Usetaddress_: rjmp Usetaddress
Usetconfiguration_: rjmp Usetconfiguration
Ureadmem_: rjmp Ureadmem
Uwritemem_: rjmp Uwritemem


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MEM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Ureadmem:
	push	r0
	lds	r30,UEDATX ; wValue (lo)
	lds	r31,UEDATX ; wValue (hi)
	ld	r0,Z

	rcall	setupack
	rcall	waitin

	sts	UEDATX,r0
	rcall	sendin
	rcall	waitout
	pop	r0
	ret

Uwritemem:
	push	r0
	lds	r30,UEDATX	; wValue (lo)
	lds	r31,UEDATX	; wValue (hi)
	lds	r0,UEDATX	; wIndex (lo)
	st	Z,r0

	rcall	setupack
	rcall	sendin
	rcall	waitin

	pop	r0
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SET_CONFIGURATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Usetconfiguration:
	rcall	setupack
	rcall	sendin
	rcall	waitin
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GET_DESCRIPTOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Ugetdescriptor:
	lds	r16,UEDATX ; wValue (lo), discard
	lds	r16,UEDATX ; wValue (hi)
	
	lds	r17,UEDATX ; wIndex (lo), discard
	lds	r17,UEDATX ; wIndex (hi), discard
	
	lds	r17,UEDATX ; wLength (lo)
	lds	r18,UEDATX ; wLength (hi)

	push	r16
	rcall	setupack
	rcall	waitin
	pop	r16

	cpi	r16,0x01
	breq	devdescr
	cpi	r16,0x02
	breq	confdescr

	rcall	stall
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Send device descriptor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

confdescr:
	ldi	r16,18
	rcall	pktlen

	ldi	r30,lo8(confdescr_data)
	ldi	r31,hi8(confdescr_data)

	rcall	writeblock
	rcall	sendin
	rcall	waitout
	ret
	



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Send device descriptor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

devdescr:
	ldi	r16,18
	;rcall	pktlen

	ldi	r30,lo8(devdescr_data)
	ldi	r31,hi8(devdescr_data)

	rcall	writeblock
	rcall	sendin
	rcall	waitout
	ret
	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SET_ADDRESS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Usetaddress:
	lds	r16,UEDATX ; wValue (lo)
	sts	UDADDR,r16
	andi	r16,0x7f
	rcall	setupack
	rcall	sendin
	rcall	waitin
	lds	r16,UDADDR
	sbr	r16,0x80
	sts	UDADDR,r16
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GET_STATUS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Ugetstatus:
	rcall	setupack
	rcall	waitin

	clr	r16
	sts	UEDATX,r16
	sts	UEDATX,r16
	rcall	sendin
	rcall	waitout

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt (usb reset)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Iusbgen:
	push	r16
	in      r16, 0x3f
	push	r16

	lds     r16,UDINT
	sbrc	r16,3
	rjmp	usbreset

	pop	r16
	out     0x3f, r16
	pop	r16
	reti

usbreset:
	clr	r16
	sts	UDINT,r16
;	we really reset everything
	rjmp	go

