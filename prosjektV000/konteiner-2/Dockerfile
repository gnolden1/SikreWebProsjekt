FROM konteiner1

EXPOSE 8180

WORKDIR /db

#installer db verktøy
RUN apk add --no-cache sqlite
RUN sqlite3 database.db

COPY skjema.sql /db/


RUN sqlite3 database.db < skjema.sql

