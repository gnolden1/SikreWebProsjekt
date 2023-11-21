#!/bin/sh

echo "Content-type:text/plain;charset=utf-8"

echo "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS"
echo "Access-Control-Allow-Origin: http://localhost"
echo "Access-Control-Allow-Credentials: true"


TOKEN=$(echo $HTTP_COOKIE | sed 's|.*ssid=\(.*\).*|\1|')

if [ "$REQUEST_METHOD" = "OPTIONS" ]
then
	echo
	echo "Go ahead, Mr. Joestar!"
fi

if [ "$REQUEST_METHOD" = "POST" -a "$REQUEST_URI" = "/login" ]
then
	read -n$CONTENT_LENGTH
	BODY=$REPLY

        PW=$(echo $BODY | sed 's|.*<passord>\(.*\)</passord>.*|\1|')
	EPOST=$(echo $BODY | sed 's|.*<epost>\(.*\)</epost>.*|\1|')
	if [ -z "$PW" -o -z "$EPOST" ]
	then
		echo
		echo "FAILURE"
		exit
	fi

	DB_HASH=$(echo "SELECT passordhash FROM bruker WHERE epost = \"$EPOST\"" | sqlite3 /db/database.db)
                
	# TODO  Vet ikke om denne linja funker
	PW_HASH=$(echo $PW | mkpasswd -m bcrypt --stdin)
	PW_HASH=$PW  # TODO  SLETT

        if [ "$PW_HASH" = "$DB_HASH" ]
        then
        	SID=$(uuidgen -r)
		echo "INSERT INTO Sesjon VALUES (\"$SID\", \"$EPOST\")" | sqlite3 /db/database.db

                echo "Set-Cookie: ssid=$SID; Path=/; Max-Age: 3600;"
		echo
		echo "SUCCESS"
	else
		echo
                echo "FAILURE"
	fi
fi

if [ "$REQUEST_METHOD" = "DELETE" -a "$REQUEST_URI" = "/logout" ]
then
	echo "DELETE FROM Sesjon WHERE sesjonsID = \"$TOKEN\"" | sqlite3 /db/database.db
	echo "Set-Cookie: ssid=deleted; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT"
        echo
	echo "SUCCESS"
fi


if [ "$REQUEST_METHOD" = "GET" ]
then
	echo
        if [[ $REQUEST_URI = */ ]]
        then
        	echo "SELECT * from Dikt"	                      	|\
                        sqlite3 --json /db/database.db                	|\
                        jq .                                    	|\
                        sed 's|"\(.*\)": \([0-9]\+\),*|<\1> \2 </\1>|'  |\
                        sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|' 	|\
			tr -s " " | grep .....* | sed 's|^ ||'		|\
			sed 's|^\(<diktID>\)|<Dikt>\1|' 		|\
			sed 's|\(</epost>\)$|\1</Dikt>|'		|\
			sed '1i <DiktDB>' | cat - <(echo "</DiktDB>")

                        #sed "s/{/<$TAB>/"                           |\
                        #sed "s|},*|</$TAB>|"                        |\
                        #sed "s/\[/<$ROT\>/"                         |\
                        #sed "s|\],*|</$ROT>|"                       |\
                        #grep -v ": null"
	else
        	DIKT_ID=$(echo $REQUEST_URI | tr -d "/" -f 1)
                echo "SELECT * from Dikt WHERE diktID = $DIKT_ID;"     	|\
                	sqlite3 --json /db/database.db			|\
                        jq .                                            |\
                        sed 's|"\(.*\)": \([0-9]\+\),*|<\1> \2 </\1>|'	|\
                        sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|' 	|\
                        tr -s " " | grep .....* | sed 's|^ ||'		|\
			sed 's|^\(<diktID>\)|<Dikt>\1|' 		|\
			sed 's|\(</epost>\)$|\1</Dikt>|'		

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
	read -n$CONTENT_LENGTH
	BODY=$REPLY

        #SQL_SELECT epost Sesjon sesjonsID $TOKEN
	EPOST=$(echo "SELECT epost FROM Sesjon WHERE sesjonsID = \"$TOKEN\"" | sqlite3 /db/database.db)
	
	echo
        if [ -z $EPOST ]
        then
                echo "FAILURE"
        else
        	DIKT=$(echo $BODY | sed 's|.*<dikt>\(.*\)</dikt>.*|\1|')
		#SQL_INSERT Dikt "dikt, epost" "$$DIKT, $$EPOST"
		echo "INSERT INTO Dikt (dikt, epost) VALUES (\"$DIKT\", \"$EPOST\")" | sqlite3 /db/database.db
        	echo "SUCCESS"
	fi
	echo "Cookie: $HTTP_COOKIE"
	echo "Token: $TOKEN"
	echo "Email: $EPOST"
fi

if [ "$REQUEST_METHOD" = "PUT" ]
then
	read -n$CONTENT_LENGTH
	BODY=$REPLY
	
	EPOST=$(echo "SELECT epost FROM Sesjon WHERE sesjonsID = \"$TOKEN\"" | sqlite3 /db/database.db)

	echo
        if [ -z $EPOST ]
        then
        	echo "FAILURE"
        else
		#DIKT: read -n$CONTENT_LENGTH | grep -oPm1 "(?<=<dikt>)[^<]+"
        	DIKT=$(echo $BODY | sed 's|.*<dikt>\(.*\)</dikt>.*|\1|')
        	#DIKT_ID: echo $REQUEST_URI | awk -F'/ ' ' { print $NF } '
                DIKT_ID=$(echo $REQUEST_URI | tr -d "/" -f 1)
        	#SQL_UPDATE_DB Dikt dikt $DIKT diktID $DIKT_ID epost $EPOST
        	echo "UPDATE Dikt SET dikt = \"$DIKT\" WHERE diktID = $DIKT_ID AND epost = \"$EPOST\"" | sqlite3 /db/database.db
		echo "SUCCESS"
	fi
fi

if [ "$REQUEST_METHOD" = "DELETE" -a "$REQUEST_URI" != "/logout" ]
then
        #SQL_SELECT epost Sesjon sesjonsID $TOKEN
	EPOST=$(echo "SELECT epost FROM Sesjon WHERE sesjonsID = \"$TOKEN\"" | sqlite3 /db/database.db)

	echo
        if [ -z $EPOST ]
        then
        	echo "FAILURE"
        else
        	if [[ $REQUEST_URI = */ ]] # * is used for pattern matching
        	then
                	#SQL_DELETE Dikt epost $EPOST
			echo "DELETE FROM Dikt WHERE epost = \"$EPOST\"" | sqlite3 /db/database.db
    		else
        		#DIKT_ID: echo $REQUEST_URI | awk -F'/ ' ' { print $NF } '
                	DIKT_ID=$(echo $REQUEST_URI | tr -d "/" -f 1)
                	#SQL_DELETE_DB Dikt diktID $DIKT_ID epost $EPOST
			echo "DELETE FROM Dikt WHERE epost = \"$EPOST\" AND diktID = $DIKT_ID" | sqlite3 /db/database.db
		fi
		echo "SUCCESS"
        fi
fi
