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
		sscanf(argv[2],"%hhx",&v);
		teensy_writemem(a,v);
	} else {
		uint16_t a;
		sscanf(argv[1],"%hx",&a);
		printf("%02x\n",teensy_readmem(a));
	}
}

