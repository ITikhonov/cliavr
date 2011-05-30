#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>

#include "libcliavr.h"

void icpush(uint8_t a, uint8_t v) {
	static uint16_t h=0;
	static uint32_t w=0; 

	if(a&1) { // high byte
		h|=v<<8;
		if(h==0) {
			w++;
		} else {
			printf("%02hhx: %x\n",a,(w<<16)|h);
		}
	} else { // low byte
		h=v;
	}
}

void icwatch() {
	uint8_t nextread=0x0;
	for(;;) {
		char buf[32];
		uint8_t tail=teensy_readmem(0x1a);
		teensy_readblock(nextread|0x100,buf);
		//fprintf(stderr,"----\n");

		int i;
		for(i=0;i<32;i++) {
			if(nextread==tail) break;
			//fprintf(stderr,"%02hhx (%02hhx): %02hhx\n",nextread,tail,buf[i]);

			icpush(nextread,buf[i]);
			if(nextread++==0xff) break;
		}
		usleep(20000);
	}
}

int main(int argc, char *argv[]) {
	if(!teensy_open()) {
		printf("error open\n");
		return 1;
	}

	if(argc==3) {
		uint16_t a;
		uint8_t v;
		sscanf(argv[1],"%hx",&a);
		if(argv[2][0]=='+') {
			sscanf(argv[2]+1,"%hhx",&v);
			teensy_setbits(a,v);
		} else if(argv[2][0]=='-') {
			sscanf(argv[2]+1,"%hhx",&v);
			teensy_clrbits(a,v);
		} else {
			sscanf(argv[2],"%hhx",&v);
			teensy_writemem(a,v);
		}
	} else if (argc==2) {
		uint16_t a;
		if(argv[1][0]=='.') {
			sscanf(argv[1],".%hx",&a);
			char buf[32];
			if(teensy_readblock(a,buf)) {
				int i;
				printf("%04hx: ",a);
				for(i=0;i<16;i++) { printf("%02hhx ",buf[i]); }
				printf("\n%04hx: ",a+16);
				for(i=16;i<32;i++) { printf("%02hhx ",buf[i]); }
				printf("\n");
			} else {
				printf("error\n");
			}
		} else if(argv[1][0]=='i') {
			icwatch();
		} else {
			sscanf(argv[1],"%hx",&a);
			printf("%02x\n",teensy_readmem(a));
		}
	} else {

		printf("read memory: %s 4e\n",argv[0]);
		printf("write memory: %s 4e ff\n",argv[0]);
		printf("clear bits: %s 4e -ff\n",argv[0]);
		printf("set bits: %s 4e +ff\n",argv[0]);
	}
}

