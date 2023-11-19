FROM konteiner1

EXPOSE 8180

COPY ./cgi_2.sh /usr/local/apache2/cgi-bin/cgi.sh
RUN chmod +x /usr/local/apache2/cgi-bin/cgi.sh

WORKDIR /db

#installer db verktøy
RUN apk add --no-cache sqlite
RUN sqlite3 database.db

COPY skjema.sql /db/


RUN sqlite3 database.db < skjema.sql

CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"
