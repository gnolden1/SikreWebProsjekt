#include <stdio.h>
#include <stdlib.h>

int main() {
	char *method = getenv("HTTP_REQUEST_METHOD");
	printf("Request method: %s\n\n", method);
	printf("Hello World\n");

	return 0;
}
