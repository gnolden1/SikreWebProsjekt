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


// TODO if lenght is ever greater than length of buffer, exit program
// TODO strncpy instead of strcpy : does not work?


struct mimeNode {
	char *fileType;
	char *fileExts;
	struct mimeNode *next;
};


void printFile(FILE *file, long fileSize);
struct mimeNode *loadMimeTypes();
char *getMimeType(struct mimeNode *head, char *targetExt);


int main (int argc, char *argv[]) {
	int ppid = getppid();

	int port;
	if (ppid == 1) {
		if (argc != 2 || (*argv[1] != '0' && *argv[1] != '1')) {
			printf("Expecting one (1) argument: 0 for root, 1 for nonroot.\nargc = %d\n", argc);
			for (int i = 0; i < argc; i++)
				printf("%s\n", argv[i]);
			exit(2);
		} 
		if (*argv[1] == '0')
			port = 80;
		else
			port = 8880;
	} else {
		if (getuid() == 0)
			port = 80;
		else
			port = 8880;
	}
	
	// Demoniserer tjeneren
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
  	lok_adr.sin_port        = htons((u_short)port); 
  	lok_adr.sin_addr.s_addr = htonl(         INADDR_ANY);

  	// Kobler sammen socket og lokal adresse
  	if ( 0==bind(sd, (struct sockaddr *)&lok_adr, sizeof(lok_adr)) )
  		fprintf(stderr, "Prosess %d er knyttet til port %d.\n", getpid(), port);
  	else
    		exit(1);
	
	// Laster mime.types inn i minne
	struct mimeNode *mimeHead = loadMimeTypes();
	
	// Skaffer sti til directory programmet kjøres fra
	char linkBuffer[256];
	char dirPath[256];
	readlink("/proc/self/exe", linkBuffer, 255);
	char *end = strrchr(linkBuffer, '/');
	memcpy(dirPath, linkBuffer, end - linkBuffer);

	// Omdirigerer stderr til logfil
	char logPath[256];
	memcpy(logPath, dirPath, 200);
	strcat(logPath, "/../var/log/debug.log");
	int logfd = open(logPath, O_RDWR | O_APPEND);
	dup2(logfd, 2);
	
	// Skaffer uid til brukeren prosessen skal kjøres som
	struct passwd *p;
	if (ppid != 1) {
		p = getpwnam("webserver");
		if (p == NULL) {
			printf("Error getting user id for user webserver. Does the user \"webserver\" exist?\n");
			exit(1);
		}
	}

	// Endrer root directory
	if (ppid != 1) {
		char newRootPath[256];
		memcpy(newRootPath, dirPath, 256);
		strcat(newRootPath, "/../var/www");
		chroot(newRootPath);
	}

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
			// TODO month + 1, hours + 2 (wsl time?), time always two digits
			fprintf(stderr, "\n%04d-%02d-%02d %02d:%02d:%02d New connection.\n", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour + 2, tm.tm_min, tm.tm_sec);
      	
			// Setter socket som stdout
			dup2(ny_sd, 1);
			
			// Leser og dekoder forespørsel fra klient
			char buffer[256];
			int length;
			char ch[2];
			char *c;

			char *requestMethod;
			char *fileName;
			char *adjustedFileName;
			char *queryString;
			char *fileExt;
			char *mimeType;

			// Leser request method
			length = 0;
			read(ny_sd, ch, sizeof(char));
			while (*ch != ' ') {
				buffer[length] = *ch;
				length++;
				read(ny_sd, ch, sizeof(char));
			}
			buffer[length] = '\0';
			requestMethod = malloc(length + sizeof('\0'));
			strcpy(requestMethod, buffer);
			fprintf(stderr, "%s ", requestMethod);

			// Leser filnavn
			length = 0;
			read(ny_sd, ch, sizeof(char));
			while (*ch != ' ' && *ch != '?') {
				buffer[length] = *ch;
				length++;
				read(ny_sd, ch, sizeof(char));
			}
			buffer[length] = '\0';
			fileName = malloc(length + sizeof('\0'));
			strcpy(fileName, buffer);
			fprintf(stderr, "%s", fileName);

			// Leser query string
			if (*ch == '?') {
				length = 0;
				read(ny_sd, ch, sizeof(char));
				while (*ch != ' ') {
					buffer[length] = *ch;
					length++;
					read(ny_sd, ch, sizeof(char));
				}
				buffer[length] = '\0';
				queryString = malloc(length + sizeof('\0'));
				strcpy(queryString, buffer);
			} else 
				queryString = NULL;
			if (queryString != NULL)
				fprintf(stderr, "?%s", queryString);
			fprintf(stderr, " HTTP/1.1\n");

			// Prefikser og suffikser filnavn etter behov
			char *prefix = "/var/www";
			char *suffix = "index.html";
			length = strlen(fileName);
			if (ppid == 1)
				length += strlen(prefix);
			if (strcmp(fileName, "/") == 0)
				length += strlen(suffix);
			
			adjustedFileName = malloc(length + sizeof('\0'));
			if (ppid == 1) {
				strcpy(adjustedFileName, prefix);
				strncat(adjustedFileName, fileName, strlen(fileName));
			} else 
				strcpy(adjustedFileName, fileName);

			if (strcmp(fileName, "/") == 0)
					strncat(adjustedFileName, suffix, strlen(suffix));

			fprintf(stderr, "Adjusted filename: %s\n", adjustedFileName);

			// Skaffer file extension
			c = strchr(adjustedFileName, '.');
			if (c != NULL) {
				c++;
				fileExt = malloc(strlen(c) + sizeof('\0'));
				strcpy(fileExt, c);
			}

			fprintf(stderr, "File extension: %s\n", fileExt);

			// Finner mimetype for gitt file extension
			if (fileExt == NULL)
				mimeType = NULL;
			else if (strcmp(fileExt, "asis") == 0)
				mimeType = "asis";
			else if (strcmp(fileExt, "cgi") == 0)
				mimeType = "cgi";
			else
				mimeType = getMimeType(mimeHead, fileExt);

			fprintf(stderr, "Mimetype: %s\n", mimeType);

			// Leser og skriver ut filer, rapporterer evt feilmeldinger
			FILE *file = fopen(adjustedFileName, "r");
			if (file == NULL)
				if (errno == ENOENT)
					printf("HTTP/1.1 404 Not Found\r\n\r\n404 Page Not Found\r\n");
				else
					printf("HTTP/1.1 500 Internal Server Error\r\n\r\n500 Internal Server Error\r\n");
			else if (mimeType == NULL)
				printf("HTTP/1.1 415 Unsupported Media Type\r\n\r\n415 Unsupported Media Type\r\n");
			else {
				struct stat st;
				stat(adjustedFileName, &st);
				if (strcmp(mimeType, "asis") != 0)
					printf("HTTP/1.1 200 OK\r\nContent-Type: %s\r\n\n", mimeType);
				printFile(file, st.st_size);
			}

      			fflush(stdout);

      			// Sørger for å stenge socket for skriving og lesing
      			// NB! Frigjør ingen plass i fildeskriptortabellen
      			
			free(requestMethod);
			free(fileName);
			free(adjustedFileName);
			free(queryString);
			free(fileExt);
			free(mimeType);
			
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
