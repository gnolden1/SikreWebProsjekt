FROM konteiner1

EXPOSE 8180

COPY ./mp3cgiV002.sh /usr/local/apache2/cgi-bin/cgi.sh
RUN chmod +x /usr/local/apache2/cgi-bin/cgi.sh

WORKDIR /db

#installer db verktøy
RUN apk add --no-cache sqlite
RUN sqlite3 database.db

#installerer jq for å få sh scriptet til å funke:
#Installs:
RUN apk add --no-cache jq
# apk add uuidgen

# chown -R "www-data":"www-data" /db/

COPY skjema.sql /db/

RUN sqlite3 database.db < skjema.sql

CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"
