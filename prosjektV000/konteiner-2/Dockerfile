FROM konteiner1

EXPOSE 8180

WORKDIR /db

#Installs:
RUN apk add --no-cache jq
RUN apk add --no-cache uuidgen
RUN apk add --no-cache xmlstarlet
RUN apk add --no-cache sqlite

COPY skjema.sql /db/
RUN sqlite3 database.db < skjema.sql
RUN chown -R "www-data":"www-data" /db/

COPY ./mp3cgiV009.sh /usr/local/apache2/cgi-bin/cgi.sh
RUN chmod +x /usr/local/apache2/cgi-bin/cgi.sh

CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"
