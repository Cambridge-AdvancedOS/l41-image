#include <stdio.h>
#include <libmcp2221/libmcp2221.h>

int main(void)
{
	mcp2221_error res;
	mcp2221_t *myDev;
	wchar_t buf[256];
	int i;

	mcp2221_init();
	
	printf("Looking for devices... ");
	int count = mcp2221_find(MCP2221_DEFAULT_VID, MCP2221_DEFAULT_PID, NULL, NULL, NULL);
	printf("found %d devices\n", count);

	for (i = 0; i < count; i++) {
		myDev = mcp2221_open_byIndex(i);
		res = mcp2221_loadSerial(myDev, buf);
		if(res != MCP2221_SUCCESS)
			return (-1);
		printf("Device %d, name %s\n", i, (char *)buf);
		mcp2221_close(myDev);
	}

	return (0);
}
