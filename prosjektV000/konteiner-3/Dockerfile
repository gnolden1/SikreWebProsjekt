FROM grunnbilde
EXPOSE 8080

RUN apk add --no-cache curl
COPY ./mp4cgiV001.sh /usr/local/apache2/cgi-bin/cgi.sh
RUN chmod +x /usr/local/apache2/cgi-bin/
RUN chown -R "www-data":"www-data" /usr/local/apache2/



CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"

