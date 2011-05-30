#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>

#include "libcliavr.h"

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
		sscanf(argv[1],"%hx",&a);
		printf("%02x\n",teensy_readmem(a));
	} else {

		printf("read memory: %s 4e\n",argv[0]);
		printf("write memory: %s 4e ff\n",argv[0]);
		printf("clear bits: %s 4e -ff\n",argv[0]);
		printf("set bits: %s 4e +ff\n",argv[0]);
	}
}

