#include <arpa/inet.h>
#include <unistd.h> 
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <pwd.h>
#include <signal.h>
#include <time.h>
#include <errno.h>
#include <sys/stat.h>


#define LOKAL_PORT 80
#define BAK_LOGG 10 // Størrelse på for kø ventende forespørsler 


void printFile(FILE *file, long fileSize);
void getSubstring(char *dest, char *src, const char *delim, int offset);
int getNumOfSubstrings(char *src, const char *delim);
struct mimeNode *loadMimeTypes();
char *getMimeType(struct mimeNode *head, char *targetExt);
struct headerNode *getRequestHeader(char *httpRequest);
void freeRequestHeader(struct headerNode *node);
char *getHeaderField(struct headerNode *head, char *targetField);


struct mimeNode {
	char *fileType;
	char *fileExts;
	struct mimeNode *next;
};

struct headerNode {
	char *field;
	char *value;
	struct headerNode *next;
};


int main () {
	// Demoniserer tjeneren
	int ppid = getppid();

	if (ppid != 1) {
		if (fork() > 0)
			exit(0);
		setsid();
		signal(SIGHUP, SIG_IGN);
		if (fork() > 0)
			exit(0);
	}

	struct sockaddr_in  lok_adr;
  	int sd, ny_sd;

  	// Setter opp socket-strukturen
  	sd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  	// For at operativsystemet ikke skal holde porten reservert etter tjenerens død
  	setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, &(int){ 1 }, sizeof(int));

  	// Initierer lokal adresse
  	lok_adr.sin_family      = AF_INET;
  	lok_adr.sin_port        = htons((u_short)LOKAL_PORT); 
  	lok_adr.sin_addr.s_addr = htonl(         INADDR_ANY);

  	// Kobler sammen socket og lokal adresse
  	if ( 0==bind(sd, (struct sockaddr *)&lok_adr, sizeof(lok_adr)) )
  		fprintf(stderr, "Prosess %d er knyttet til port %d.\n", getpid(), LOKAL_PORT);
  	else
    		exit(1);
	
	// Laster mime.types inn i minne
	struct mimeNode *mimeHead = loadMimeTypes();

	// Skaffer uid til brukeren prosessen skal kjøres som
	struct passwd *p;
	if (ppid != 1) {
		p = getpwnam("webserver");
		if (p == NULL) {
			printf("Error getting user id for user webserver.\n");
			exit(1);
		}
	}

	// Skaffer sti til directory programmet kjøres fra
	char linkBuffer[256];
	char dirPath[256];
	readlink("/proc/self/exe", linkBuffer, 256);
	char *end = strrchr(linkBuffer, '/');
	memcpy(dirPath, linkBuffer, end - linkBuffer);

	// Omdirigerer stderr til logfil
	char logPath[256];
	memcpy(logPath, dirPath, 200);
	strcat(logPath, "/../var/log/debug.log");
	int logfd = open(logPath, O_RDWR | O_APPEND);
	dup2(logfd, 2);
	
	// Endrer root directory
	char newRootPath[256];
	memcpy(newRootPath, dirPath, 256);
	strcat(newRootPath, "/../var/www");
	
	if (ppid != 1)
		chroot(newRootPath);

	// Setter prosessen til ny bruker
	if (ppid != 1)
		setuid(p->pw_uid);

	// Forhindrer spawning av zombier
	signal(SIGCHLD, SIG_IGN);

  	// Venter på forespørsel om forbindelse
  	listen(sd, BAK_LOGG); 
  	while(1){ 

    		// Aksepterer mottatt forespørsel
    		ny_sd = accept(sd, NULL, NULL);    

    		if(0==fork()) {
			// Loggfører tilkoblingen
			time_t t = time(NULL);
			struct tm tm = *localtime(&t);
			fprintf(stderr, "%d-%d %d:%d:%d New connection.\n", tm.tm_mon, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
      	
			// Setter socket som stdout
			dup2(ny_sd, 1);
			
			// Leser og dekoder forespørsel fra klient
			char buffer[2048];
			read(ny_sd, buffer, 2048);
			fprintf(stderr, "Read to buffer\n");

			char *body = strstr(buffer, "\r\n\r\n");
			*body = '\0';
			body += 4;
			fprintf(stderr, "Split header and body\n");

			struct headerNode *requestHeader = getRequestHeader(buffer);
			fprintf(stderr, "Read headers\n");

			char request[128];
			getSubstring(request, buffer, "\n", 0);
			fprintf(stderr, "Got request\n");

			char method[8];
			getSubstring(method, request, " ", 0);
			fprintf(stderr, "Got request method\n");

			char fileName[128];
			char *queryString;
			
			if (ppid != 1)
				getSubstring(fileName, request, " ", 1);
			else {
				strcpy(fileName, "/var/www");
				char tempBuffer[128];
				getSubstring(tempBuffer, request, " ", 1);
				strcat(fileName, tempBuffer);
			}
			fprintf(stderr, "Got filename\n");
			
			if (strchr(fileName, '?') == NULL)
				queryString = NULL;
			else {
				queryString = strchr(fileName, '?');
				*queryString = '\0';
				queryString++;
			}
			fprintf(stderr, "Got query string\n");

			if (strcmp(fileName, "/") == 0 || strcmp(fileName, "/var/www/") == 0) 
				strcat(fileName, "index.html");

			char fileType[32];
			// Hvis fileType er NULL er det et database query
			if (strchr(fileName, '.') == NULL)
				*fileType = '\0';
			else
				getSubstring(fileType, fileName, ".", getNumOfSubstrings(fileName, ".") - 1);

			// Finner mimetype for gitt file extension
			char *mimeType;
			if (strcmp(fileType, "asis") == 0)
				mimeType = "asis";
			else if (strcmp(fileType, "cgi") == 0)
				mimeType = "cgi";
			else
				mimeType = getMimeType(mimeHead, fileType);

			char *contentLength = getHeaderField(requestHeader, "Content-Length");
			char *contentType = getHeaderField(requestHeader, "Content-Type");

			//char *body = strtok(buffer, "\r\n\r\n");
			//body = strtok(NULL, "\r\n\r\n");
			setenv("HTTP_BODY", body, 1);
			//setenv("HTTP_BODY", "This is a test", 1);


			fprintf(stderr, "Reached the point of reply\n");
			// Åpner og skriver fil, evt feilmeldinger
			if (*fileType == '\0') {
				printf("HTTP/1.1 200 OK\r\n\n");

				setenv("HTTP_REQUEST_METHOD", method, 1);
				setenv("DIKTID", fileName, 1);
				
				if (queryString != NULL)
					setenv("HTTP_QUERY_STRING", queryString, 1);
				
				if (contentType != NULL)
					setenv("HTTP_CONTENT_TYPE", contentType, 1);
				
				if (contentLength != NULL)
					setenv("HTTP_CONTENT_LENGTH", contentLength, 1); 
				
				printf("You have called the script!\n");
				fflush(stdout);
      				freeRequestHeader(requestHeader);
				execl("/var/www/script.sh", "/var/www/script.sh", NULL);
				//shutdown(ny_sd, SHUT_RDWR);
      				//exit(0);
			}

			FILE *file = fopen(fileName, "r");
			if (file == NULL)
				if (errno == ENOENT)
					printf("HTTP/1.1 404 Not Found\r\n\r\n404 Page Not Found\r\n");
				else
					printf("HTTP/1.1 500 Internal Server Error\r\n\r\n500 Internal Server Error\r\n");
			else if (mimeType == NULL)
				printf("HTTP/1.1 415 Unsupported Media Type\r\n\r\n415 Unsupported Media Type\r\n");
			else {
				struct stat st;
				stat(fileName, &st);
				printf("HTTP/1.1 200 OK\r\nContent-Type: %s\r\n\n", mimeType);
				printFile(file, st.st_size);
			}

      			fflush(stdout);

      			// Sørger for å stenge socket for skriving og lesing
      			// NB! Frigjør ingen plass i fildeskriptortabellen
      			freeRequestHeader(requestHeader);
			shutdown(ny_sd, SHUT_RDWR);
      			exit(0);
    		} else {
      			close(ny_sd);
    		}
  	}
  	return 0;
}


void printFile(FILE *file, long fileSize) {
	char ch;
	for (int i = 0; i < fileSize; i++) {
		ch = fgetc(file);
		printf("%c", ch);
	}
}


void getSubstring(char *dest, char *src, const char *delim, int offset) {
	char string[2048];
	strcpy(string, src);

	char *token = strtok(string, delim);
	for (int i = 0; i < offset; i++) 
		token = strtok(NULL, delim);

	strcpy(dest, token);
}


int getNumOfSubstrings(char *src, const char *delim) {
	char string[2048];
	strcpy(string, src);

	int counter = 1;
	strtok(string, delim);
	while (strtok(NULL, delim) != NULL)
		counter++;

	return counter;
}


struct mimeNode *loadMimeTypes() {
	FILE *mimeFile = fopen("/etc/mime.types", "r");
	struct mimeNode *head = NULL;

	char buffer[256];
	char mimeType[170];
	char exts[86];
	char *token;

	while (fgets(buffer, 256, mimeFile) != NULL) {
		if (strlen(buffer) < 2 || buffer[0] == '#')
			continue;

		token = strtok(buffer, "\n");
		token = strtok(token, "\t");
		strcpy(mimeType, token);
		token = strtok(NULL, "\t");
		if (token == NULL)
			continue;
		strcpy(exts, token);

		struct mimeNode *node = malloc(sizeof(struct mimeNode));
		node->fileType = malloc(strlen(mimeType) + sizeof('\0'));
		node->fileExts = malloc(strlen(exts) + sizeof('\0'));
		strcpy(node->fileType, mimeType);
		strcpy(node->fileExts, exts);
		node->next = NULL;

		if (head == NULL)
			head = node;
		else {
			struct mimeNode *ptr = head;
			while (ptr->next != NULL)
				ptr = ptr->next;
			ptr->next = node;
		}
	}

	fclose(mimeFile);
	return head;
}


char *getMimeType(struct mimeNode *head, char *targetExt) {
	struct mimeNode *ptr = head;
	char exts[86];
	char *token;

	while (ptr != NULL) {
		strcpy(exts, ptr->fileExts);
		token = strtok(exts, " ");

		while (token != NULL) {
			if (strcmp(token, targetExt) == 0) 
				return ptr->fileType;

			token = strtok(NULL, " ");
		}

		ptr = ptr->next;
	}

	return NULL;
}


struct headerNode *getRequestHeader(char *httpRequest) {
	char request[2048];
	strcpy(request, httpRequest);
	char *token;
	char *lineSave = NULL;
	char *fieldSave = NULL;
	char line[128];
	struct headerNode *head = NULL;

	token = strtok_r(request, "\r\n\r\n", &lineSave);
	token = strtok_r(NULL, "\r\n", &lineSave);

	while (token != NULL && strlen(token) > 3) {
		struct headerNode *node = malloc(sizeof(struct headerNode));
		strcpy(line, token);
		
		token = strtok_r(line, ": ", &fieldSave);
		node->field = malloc(strlen(token) + sizeof('\0'));
		strcpy(node->field, token);
		
		token = strtok_r(NULL, ": ", &fieldSave);
		node->value = malloc(strlen(token) + sizeof('\0'));
		strcpy(node->value, token);

		node->next = NULL;

		if (head == NULL)
			head = node;
		else {
			struct headerNode *ptr = head;
			while (ptr->next != NULL)
				ptr = ptr->next;
			ptr->next = node;
		}

		token = strtok_r(NULL, "\r\n", &lineSave);
	}

	return head;
}


void freeRequestHeader(struct headerNode *node) {
	if (node->next != NULL)
		freeRequestHeader(node->next);

	free(node->field);
	free(node->value);
	free(node);
}

char *getHeaderField(struct headerNode *head, char *targetField) {
	struct headerNode *ptr = head;
	while (ptr != NULL) {
		if (strcmp(ptr->field, targetField) == 0)
			return ptr->value;

		ptr = ptr->next;
	}

	return NULL;
}
