#include <stdio.h>
#include <stdlib.h>
#include <libmcp2221/libmcp2221.h>

int main(int argc, char **argv)
{
	mcp2221_error res;
	mcp2221_t *myDev;
	wchar_t *serial;
	int idx;

	puts("Starting!");

	if (argc != 3) {
		printf("Usage: %s idx serial\n", argv[0]);
		return (-1);
	}

	idx = atoi(argv[1]);
	serial = (wchar_t *)argv[2];

	printf("Trying to update serial for idx %d, serial %s\n", idx, (char *)serial);

	mcp2221_init();

	// Get list of MCP2221s
	printf("Looking for devices... ");
	int count = mcp2221_find(MCP2221_DEFAULT_VID, MCP2221_DEFAULT_PID, NULL, NULL, NULL);
	printf("found %d devices\n", count);

	myDev = mcp2221_open_byIndex(idx);
	if(!myDev)
	{
		mcp2221_exit();
		puts("No MCP2221s found");
		getchar();
		return 0;
	}

	res = mcp2221_saveSerial(myDev, serial);
	if(res != MCP2221_SUCCESS)
		return (-1);

	mcp2221_saveSerialEnumerate(myDev, 1);

	printf("Serial updated\n");

	return (0);
}
