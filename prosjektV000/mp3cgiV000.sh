#!/bin/sh

DATABASE_FILE="/db/dikt.db"

SQL_SELECT () {
        QUERY: "SELECT $1 FROM $2 WHERE $3 = $4;" #$1: SELECT / $2: FROM / $3: WHERE A / $4: EQUAL B
        sqlite3 $DATABASE_FILE $QUERY
}

SQL_SELECT_DB () {
        QUERY: "SELECT $1 FROM $2 WHERE $3 = $4;" #$1: SELECT / $2: FROM / $3: WHERE A / $4: EQUAL B / $5: AND C / $6: EQUAL D
        sqlite3 $DATABASE_FILE $QUERY
}

SQL_INSERT () {
        QUERY: "INSERT INTO $1 ($2) VALUES ($3);" #$1: TABLE / $2: COLUMNS / $3: VALUES
        sqlite3 $DATABASE_FILE $QUERY
}

SQL_DELETE () {
        QUERY: "DELETE FROM $1 WHERE $2 = $3;" #$1: TABLE / $2: FROM / $3: WHERE A / $4: EQUAL B
        sqlite3 $DATABASE_FILE $QUERY
}

SQL_DELETE_DB () {
        QUERY: "DELETE FROM $1 WHERE $2 = $3 AND $4 = $5;" #$1: TABLE / $2: FROM / $3: WHERE A / $4: EQUAL B / $5: AND C / $6: EQUAL D
        sqlite3 $DATABASE_FILE $QUERY
}

SQL_UPDATE_DB () {
        QUERY: "UPDATE $1 SET $2=$3 WHERE $4 = $5 AND $6 = $7;" #$1: TABLE / $2: ROW / $3: VALUE A / $4: WHERE A / $5: EQUAL B / $4: AND C / $5: EQUAL D
        sqlite3 $DATABASE_FILE $QUERY
}

# Skriver {SQL QUERY} UPDATE Dikt SET dikt=$DIKT WHERE diktID = $DIKT_ID AND epost = $EPOST;ut 'http-header' for 'plain-text'
echo "Content-type:text/plain;charset=utf-8"

# Skriver ut tom linje for .. skille hodet fra kroppen
echo


echo REQUEST_URI:    $REQUEST_URI
echo REQUEST_METHOD: $REQUEST_METHOD
TOKEN=$($HTTP_COOKIE | cut -d '=' -f2 | cut -d ';' -f1)

if [ "$REQUEST_METHOD" == "POST"  -a "$REQUEST_URI" == "*/login" ]
        then
                PW: echo read -n$CONTENT_LENGTH | grep -oPm1 "(?<=<passord>)[^<]+"
                EPOST: echo read -n$CONTENT_LENGTH | grep -oPm1 "(?<=<epost>)[^<]+"

                DB_HASH: SQL_SELECT passordhash Bruker epost $EPOST
                PW_HASH: $PW | mkpasswd -m bcrypt --stdin

                if [ $PW_HASH == $DB_HASH ]
                        then
                        SID: uuidgen -r
                        SQL_INSERT Sesjon "sesjonsID, epost" "$$SID, $$EPOST"

                        echo "Set-cookie: ssid=$SID"
                        echo "Velykket innlogging. \n\n"

                else
                        echo "Feil brukernavn eller passord. \n\n"
                fi
fi

if [ "$REQUEST_METHOD" == "DELETE"  && "$REQUEST_URI" == "*/logut" ]
        then
        SQL_DELETE Sesjon sesjonsID $TOKEN

                echo "Du har blitt logget ut."
fi


if [ "$REQUEST_METHOD" == "GET" ];
        then
echo "entered get"
        if [[ $REQUEST_URI = */ ]] # * is used for pattern matching
                then
echo "entered request uri"
                echo "SELECT * from Dikt;"                      |\
                        sqlite3 --json /db/database.db                |\
                        jq .                                    |\
                        sed 's|"\(.*\)": \([0-9]\+\),*|<\1> \2 </\1>|'  |\
                        sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|' |\
                        grep .....* | tr -s " " | sed 's|^ ||'

                        #sed "s/{/<$TAB>/"                           #|\
                        #sed "s|},*|</$TAB>|"                        |\
                        #sed "s/\[/<$ROT\>/"                         |\
                        #sed "s|\],*|</$ROT>|"                       |\
                        #grep -v ": null"

                else
                DIKT_ID: echo $REQUEST_URI | awk -F'/ ' ' { print $NF } '
                echo "SELECT * from Dikt WHERE diktID = $DIKT_ID;"  |\
                        sqlite3 --json dikt.db                          |\
                        jq .                                            |\
                        sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|'    |\
                        sed "s/{/<$TAB>/"                               |\
                        sed "s|},*|</$TAB>|"                            |\
                        sed "s/\[/<$ROT\>/"                             |\
                        sed "s|\],*|</$ROT>|"                           |\
                        grep -v ": null"
        fi
fi

if [ "$REQUEST_METHOD" == "POST" ];
        then
        SQL_SELECT epost Sesjon sesjonsID $TOKEN

        if [ $EPOST == "" ]
                then
                echo "Du er ikke logget inn."
                exit
        fi

        DIKT: read -n$CONTENT_LENGTH | grep -oPm1 "(?<=<dikt>)[^<]+"

        SQL_INSERT Dikt "dikt, epost" "$$DIKT, $$EPOST"

        echo "Du har lagt ut et dikt."
fi

if [ "$REQUEST_METHOD" == "PUT" ];
        then
        SQL_SELECT epost Sesjon sesjonsID $TOKEN

        if [ $EPOST == "" ]
                then
                        echo "Du er ikke logget inn."
                        exit
        fi

        DIKT: read -n$CONTENT_LENGTH | grep -oPm1 "(?<=<dikt>)[^<]+"

        DIKT_ID: echo $REQUEST_URI | awk -F'/ ' ' { print $NF } '

        SQL_UPDATE_DB Dikt dikt $DIKT diktID $DIKT_ID epost $EPOST

        echo "Du har oppdatert ut et dikt."
fi

if [ "$REQUEST_METHOD" == "DELETE" ]; then
        SQL_SELECT epost Sesjon sesjonsID $TOKEN

        if [ $EPOST == "" ]
                then
                        echo "Du er ikke logget inn."
                        exit
        fi

        if [ $REQUEST_URI == */ ] # * is used for pattern matching
        then
                SQL_DELETE Dikt epost $EPOST

                echo "Du har slettet alle diktene dine."
    else
        DIKT_ID: echo $REQUEST_URI | awk -F'/ ' ' { print $NF } '
                SQL_DELETE_DB Dikt diktID $DIKT_ID epost $EPOST

                echo "Du har slettet et dikt."
        fi
fi
