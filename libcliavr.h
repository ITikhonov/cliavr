#include <stdint.h>

int teensy_open(void);
void teensy_close(void);

int teensy_writemem(uint16_t addr, uint8_t v);
int teensy_readmem(uint16_t addr);

int teensy_setbits(uint16_t addr, uint8_t v);
int teensy_clrbits(uint16_t addr, uint8_t v);

