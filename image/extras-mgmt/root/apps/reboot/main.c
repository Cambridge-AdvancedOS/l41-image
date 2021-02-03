#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <libmcp2221/libmcp2221.h>

#define Sleep(ms) usleep(ms * 1000)

static int
reboot_node(mcp2221_t *myDev)
{
	mcp2221_error res;

	// Configure GPIOs
	printf("Configuring GPIOs... ");
	mcp2221_gpioconfset_t gpioConf = mcp2221_GPIOConfInit();

	// Configure GPIO 3 as OUTPUT HIGH
	gpioConf.conf[0].gpios		= MCP2221_GPIO3;
	gpioConf.conf[0].mode		= MCP2221_GPIO_MODE_GPIO;
	gpioConf.conf[0].direction	= MCP2221_GPIO_DIR_OUTPUT;

	// Apply config
	mcp2221_setGPIOConf(myDev, &gpioConf);

	// Also save config to flash
	mcp2221_saveGPIOConf(myDev, &gpioConf);

	puts("done");

	res = mcp2221_setGPIO(myDev, MCP2221_GPIO3, MCP2221_GPIO_VALUE_LOW);
	if(res != MCP2221_SUCCESS)
		return (-1);

	sleep (1);

	res = mcp2221_setGPIO(myDev, MCP2221_GPIO3, MCP2221_GPIO_VALUE_HIGH);
	if(res != MCP2221_SUCCESS)
		return (-2);

	printf("Node rebooted successfully\n");

	return (0);
}

int main(int argc, char **argv)
{
	mcp2221_error res;
	mcp2221_t *myDev;
	wchar_t *serial;
	wchar_t buf[36];
	int error;
	int i;

	puts("Starting!");

	if (argc != 2) {
		printf("Usage: %s serial\n", argv[0]);
		return (-1);
	}

	serial = (wchar_t *)argv[1];

	printf("Trying to reboot server with serial %s\n", (char *)serial);

	mcp2221_init();

	// Get list of MCP2221s
	printf("Looking for devices... ");
	int count = mcp2221_find(MCP2221_DEFAULT_VID, MCP2221_DEFAULT_PID, NULL, NULL, NULL);
	printf("found %d devices\n", count);

	error = 0;

	for (i = 0; i < count; i++) {
		myDev = mcp2221_open_byIndex(i);
		res = mcp2221_loadSerial(myDev, buf);
		if(res != MCP2221_SUCCESS)
			return (-1);

		if (strcmp((char *)buf, (char *)serial) == 0) {
			printf("Node found. rebooting\n");
			error = reboot_node(myDev);
			mcp2221_close(myDev);
			goto done;
		}

		mcp2221_close(myDev);
	}

	printf("Node '%s' not found\n", (char *)serial);
done:
	mcp2221_exit();

	return (error);
}

