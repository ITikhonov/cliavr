
int teensy_open(void);
void teensy_close(void);

int teensy_writemem(uint16_t addr, uint8_t v);
int teensy_readmem(uint16_t addr);

