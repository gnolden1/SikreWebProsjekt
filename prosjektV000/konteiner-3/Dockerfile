FROM grunnbilde
EXPOSE 8080

RUN apk add --no-cache curl libxml2-utils
COPY ./cgi.sh /usr/local/apache2/cgi-bin/cgi.sh
RUN chmod +x /usr/local/apache2/cgi-bin/
RUN chown -R "www-data":"www-data" /usr/local/apache2/cgi-bin



CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"

