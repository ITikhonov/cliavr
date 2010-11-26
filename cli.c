#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>

#include <usb.h>

usb_dev_handle * open_usb_device(int vid, int pid)
{
	struct usb_bus *bus;
	struct usb_device *dev;
	usb_dev_handle *h;
	char buf[128];
	int r;

	usb_init();
	usb_find_busses();
	usb_find_devices();
	for (bus = usb_get_busses(); bus; bus = bus->next) {
		for (dev = bus->devices; dev; dev = dev->next) {
			if (dev->descriptor.idVendor != vid) continue;
			if (dev->descriptor.idProduct != pid) continue;
			h = usb_open(dev);
			if (!h) {
				printf("Found device but unable to open");
				continue;
			}
			#ifdef LIBUSB_HAS_GET_DRIVER_NP
			r = usb_get_driver_np(h, 0, buf, sizeof(buf));
			if (r >= 0) {
				r = usb_detach_kernel_driver_np(h, 0);
				if (r < 0) {
					usb_close(h);
					printf("Device is in use by \"%s\" driver", buf);
					continue;
				}
			}
			#endif
			r = usb_claim_interface(h, 0);
			if (r < 0) {
				usb_close(h);
				printf("Unable to claim interface, check USB permissions");
				continue;
			}
			return h;
		}
	}
	printf("no found\n");
	return NULL;
}

static usb_dev_handle *libusb_teensy_handle = NULL;


void teensy_close(void)
{
	if (!libusb_teensy_handle) return;
	usb_release_interface(libusb_teensy_handle, 0);
	usb_close(libusb_teensy_handle);
	libusb_teensy_handle = NULL;
}

int teensy_open(void)
{
	teensy_close();
	libusb_teensy_handle = open_usb_device(0x16C0, 0x0480);
	if (libusb_teensy_handle) return 1;
	return 0;
}

int teensy_writemem(uint16_t addr, uint8_t v)
{
	int r;
	char buf;

	if (!libusb_teensy_handle) return 0;
	r = usb_control_msg(libusb_teensy_handle, 0b01000001, 0xf1, addr, v, 0, 0, 1000);
	if (r < 0) return 0;
	printf("%04x: %02hhx\n",addr,buf,v);
	return 1;
}

int teensy_readmem(uint16_t addr)
{
	int r;
	char buf;

	if (!libusb_teensy_handle) return 0;
	r = usb_control_msg(libusb_teensy_handle, 0b11000001, 0xf0, addr, 0, &buf, 1, 1000);
	if (r < 0) return 0;
	printf("%04x: %02hhx\n",addr,buf,r);
	return 1;
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
		sscanf(argv[2],"%hhx",&v);
		teensy_writemem(a,v);
	} else {
		uint16_t a;
		sscanf(argv[1],"%hx",&a);
		teensy_readmem(a);
	}
}

