#!/bin/sh

DATABASE_FILE="/db/database.db"

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
#echo


#echo REQUEST_URI:    $REQUEST_URI
#echo REQUEST_METHOD: $REQUEST_METHOD
TOKEN=$($HTTP_COOKIE | cut -d '=' -f2 | cut -d ';' -f1)

if [ "$REQUEST_METHOD" = "POST"  -a "$REQUEST_URI" = "/login" ]
        then
		read -n$CONTENT_LENGTH
		BODY=$REPLY

                PW=$(echo $BODY | sed 's|.*<passord>\(.*\)</passord>.*|\1|')
		EPOST=$(echo $BODY | sed 's|.*<epost>\(.*\)</epost>.*|\1|')

		DB_HASH=$(echo "SELECT passordhash FROM bruker WHERE epost = \"$EPOST\"" | sqlite3 /db/database.db)
                
		# TODO  Vet ikke om denne linja funker
		PW_HASH=$(echo $PW | mkpasswd -m bcrypt --stdin)

                if [ $PW_HASH == $DB_HASH ]
                        then
                        SID=$(uuidgen -r)
			echo "INSERT INTO Sesjon VALUES (\"$SID\", \"$EPOST\")" | sqlite3 /db/database.db

                        echo "Set-cookie: ssid=$SID"
			echo
                        echo "Velykket innlogging."
                else
			echo
                        echo "Feil brukernavn eller passord."
                fi
fi

if [ "$REQUEST_METHOD" = "DELETE" -a "$REQUEST_URI" = "/logout" ]
        then
	echo "DELETE FROM Sesjon WHERE sesjonsID = \"$TOKEN\"" | sqlite3 /db/database.db
        echo
	echo "Du har blitt logget ut."
fi


if [ "$REQUEST_METHOD" == "GET" ];
        then
	echo
        if [[ $REQUEST_URI = */ ]] # * is used for pattern matching
                then
echo "SELECT * FROM Sesjon" | sqlite3 /db/database.db --json | jq .
echo
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
                DIKT_ID=$(echo $REQUEST_URI | tr -d "/" -f 1)
                echo "SELECT * from Dikt WHERE diktID = $DIKT_ID;"     |\
                        sqlite3 --json /db/database.db                          |\
                        jq .                                            |\
                        sed 's|"\(.*\)": \([0-9]\+\),*|<\1> \2 </\1>|'  |\
                        sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|' |\
                        grep .....* | tr -s " " | sed 's|^ ||'

			#sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|'    |\
                        #sed "s/{/<$TAB>/"                               |\
                        #sed "s|},*|</$TAB>|"                            |\
                        #sed "s/\[/<$ROT\>/"                             |\
                        #sed "s|\],*|</$ROT>|"                           |\
                        #grep -v ": null"
        fi
fi

if [ "$REQUEST_METHOD" = "POST" -a "$REQUEST_URI" != "/login" ] 
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

if [ "$REQUEST_METHOD" = "DELETE" -a "$REQUEST_URI" != "/logout" ]
then
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
