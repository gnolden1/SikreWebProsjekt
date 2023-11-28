FROM grunnbilde
EXPOSE 8080

RUN apk add --no-cache curl
COPY ./mp4cgi.sh /usr/local/apache2/cgi-bin/cgi.sh
RUN chmod +x /usr/local/apache2/cgi-bin/cgi.sh



CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"

