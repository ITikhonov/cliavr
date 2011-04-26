from os import system,popen

def w(p,v):
	system("./cli %x %x"%(p,v))

def r(p):
	f=popen("./cli %x"%(p,),'r')
	x=f.read()
	f.close()
	return int(x,16)


ADCSRA=0x7A 
ADCSRB=0x7B 
ADMUX=0x7C 
ADCL=0x78 
ADCH=0x79
DDRF=0x30
PORTF=0x31

w(ADCSRA,0b10000000)
w(ADCSRB,0b10000000)

# 1. Drive F1 to vdd as output

w(DDRF,0b10)
w(PORTF,0b10)

def touch():

	# 2. Mux ADC to F1

	w(ADMUX,0b01000001) # internal vref, ADC1

	# 3. Ground F0 (output/zero)

	w(DDRF,0b11)
	w(PORTF,0b10)

	# 4. Turn F0 to input

	w(DDRF,0b10)

	# 5. Mux ADC to F0

	w(ADMUX,0b01000000) # internal vref, ADC0

	# 6. Do ADC read

	w(ADCSRA,0b11000000)

	while r(ADCSRA) & 0b01000000: pass

	l=r(ADCL)
	h=r(ADCH)

	return (h<<8)|l

import pygame
pygame.init()
S=pygame.display.set_mode((1024,760),pygame.DOUBLEBUF)

FB=pygame.Surface((1024,760),0,S)
FB.fill((255,255,255))


def draw():
	S.blit(FB,(0,0))
	pygame.display.flip()

a=0

yp=0

while True:
	T=touch()

	y0=int(760*(T/1024.0))

	FB.scroll(-1)
	FB.fill(0x0000FF,pygame.Rect(512,min(y0,yp),1,abs(y0-yp)))

	yp=y0
	draw()








