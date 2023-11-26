#!/bin/sh

echo "Content-type:text/plain;charset=utf-8"

echo "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS"
echo "Access-Control-Allow-Origin: http://localhost"
echo "Access-Control-Allow-Credentials: true"


REQUEST_URI=$(echo $REQUEST_URI | cut -d "?" -f 1)
TOKEN=$(echo $HTTP_COOKIE | sed 's|.*ssid=\(.*\).*|\1|')

if [ "$REQUEST_METHOD" = "OPTIONS" ]
then
	echo
	echo "OPTIONS RESPONSE BODY"
fi

if [ "$REQUEST_METHOD" = "POST" -a "$REQUEST_URI" = "/login" ]
then
	#read -n$CONTENT_LENGTH
	#BODY=$REPLY
	BODY=$(tail -c $CONTENT_LENGTH)
	
	: 'INVALID=$(echo $BODY > temp.xml && xmlstarlet val -d userLogin.dtd temp.xml | grep invalid && rm temp.xml)
	if [ $INVALID ]
	then
		echo
		echo "FAILURE"
		echo "XML INVALID"
		exit
	fi'

        PW=$(echo $BODY | sed 's|.*<passord>\(.*\)</passord>.*|\1|')
	EPOST=$(echo $BODY | sed 's|.*<epost>\(.*\)</epost>.*|\1|')
	if [ -z "$PW" -o -z "$EPOST" ]
	then
		echo
		echo "FAILURE"
		exit
	fi

	DB_HASH=$(echo "SELECT passordhash FROM bruker WHERE epost = \"$EPOST\"" | sqlite3 /db/database.db)
	PW_HASH=$(echo $PW | sha512sum | sed 's|\(^.*\) -|\1|' | sed 's| ||')

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
        	echo "SELECT * from Dikt"	                			|\
                sqlite3 --json /db/database.db                				|\
                jq .                                    				|\
                sed 's|"\(.*\)": \([0-9]\+\),*|<\1> \2 </\1>|'  			|\
                sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|' 				|\
		sed 's|> |>|' | sed 's| </|</|'						|\
		tr -s " " | grep .....* | sed 's|^ ||'					|\
		sed 's|^\(<diktID>\)|<Dikt>\n\1|' 					|\
		sed 's|\(</epost>\)$|\1\n</Dikt>|'					|\
		sed '1i <?xml version="1.0"?>'						|\
		sed '2i <!DOCTYPE DiktDB SYSTEM "http://localhost/allPoems.dtd">'	|\
		sed '3i <DiktDB>' | cat - <(echo "</DiktDB>")				
		
		:'INVALID=$(echo $RESPONSE > temp.xml && xmlstarlet val -d allPoems.dtd temp.xml | grep invalid && rm temp.xml)
		if [ $INVALID ]
		then
			echo "FAILURE"
			echo "SERVERSIDE XML INVALID"
			exit
		fi
		echo $RESPONSE'
	else
        	DIKT_ID=$(echo $REQUEST_URI | tr -d "/" -f 1)
                echo "SELECT * from Dikt WHERE diktID = $DIKT_ID;"     			|\
                sqlite3 --json /db/database.db						|\
                jq .                                            			|\
                sed 's|"\(.*\)": \([0-9]\+\),*|<\1> \2 </\1>|'				|\
                sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|' 				|\
                tr -s " " | grep .....* | sed 's|^ ||'					|\
		sed 's|^\(<diktID>\)|<Dikt>\n\1|' 					|\
		sed 's|\(</epost>\)$|\1\n</Dikt>|'					|\
		sed 's|> |>|' | sed 's| </|</|'						|\
		sed '1i <?xml version="1.0"?>'						|\
		sed '2i <!DOCTYPE DiktDB SYSTEM "http://localhost/singlePoems.dtd">'

		:'INVALID=$(echo $RESPONSE > temp.xml && xmlstarlet val -d singlePoems.dtd temp.xml | grep invalid && rm temp.xml)
		if [ $INVALID ]
		then
			echo "FAILURE"
			echo "SERVERSIDE XML INVALID"
			exit
		fi
		echo $RESPONSE'
        fi
fi

if [ "$REQUEST_METHOD" = "POST" -a "$REQUEST_URI" != "/login" ] 
then
	#read -n$CONTENT_LENGTH
	#BODY=$REPLY
	BODY=$(tail -c $CONTENT_LENGTH)

	:'INVALID=$(echo $BODY > temp.xml && xmlstarlet val -d poemSubmission.dtd temp.xml | grep invalid && rm temp.xml)
	if [ $INVALID ]
	then
		echo
		echo "FAILURE"
		echo "XML INVALID"
		exit
	fi'

	EPOST=$(echo "SELECT epost FROM Sesjon WHERE sesjonsID = \"$TOKEN\"" | sqlite3 /db/database.db)
	
	echo
        if [ -z $EPOST ]
        then
                echo "FAILURE"
        else
        	DIKT=$(echo $BODY | sed 's|.*<dikt>\(.*\)</dikt>.*|\1|')
		echo "INSERT INTO Dikt (dikt, epost) VALUES (\"$DIKT\", \"$EPOST\")" | sqlite3 /db/database.db
        	echo "SUCCESS"
	fi
fi

if [ "$REQUEST_METHOD" = "PUT" ]
then
	#read -n$CONTENT_LENGTH
	#BODY=$REPLY
	BODY=$(tail -c $CONTENT_LENGTH)
	
	:'INVALID=$(echo $BODY > temp.xml && xmlstarlet val -d poemSubmission.dtd temp.xml | grep invalid && rm temp.xml)
	if [ $INVALID ]
	then
		echo
		echo "FAILURE"
		echo "XML INVALID"
		exit
	fi'

	EPOST=$(echo "SELECT epost FROM Sesjon WHERE sesjonsID = \"$TOKEN\"" | sqlite3 /db/database.db)

	echo
        if [ -z $EPOST ]
        then
        	echo "FAILURE"
        else
        	DIKT=$(echo $BODY | sed 's|.*<dikt>\(.*\)</dikt>.*|\1|')
                DIKT_ID=$(echo $REQUEST_URI | tr -d "/" -f 1)
        	echo "UPDATE Dikt SET dikt = \"$DIKT\" WHERE diktID = $DIKT_ID AND epost = \"$EPOST\"" | sqlite3 /db/database.db
		echo "SUCCESS"
	fi
fi

if [ "$REQUEST_METHOD" = "DELETE" -a "$REQUEST_URI" != "/logout" ]
then
	EPOST=$(echo "SELECT epost FROM Sesjon WHERE sesjonsID = \"$TOKEN\"" | sqlite3 /db/database.db)

	echo
        if [ -z $EPOST ]
        then
        	echo "FAILURE"
        else
        	if [[ $REQUEST_URI = */ ]]
        	then
			echo "DELETE FROM Dikt WHERE epost = \"$EPOST\"" | sqlite3 /db/database.db
    		else
                	DIKT_ID=$(echo $REQUEST_URI | tr -d "/" -f 1)
			echo "DELETE FROM Dikt WHERE epost = \"$EPOST\" AND diktID = $DIKT_ID" | sqlite3 /db/database.db
		fi
		echo "SUCCESS"
        fi
fi
