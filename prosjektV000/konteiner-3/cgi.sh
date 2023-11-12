#!/bin/sh

# Skriver ut 'http-header' for 'plain-text'
echo "Content-type:text/plain;charset=utf-8"

# Skriver ut tom linje for å skille hodet fra kroppen
echo


echo REQUEST_URI:    $REQUEST_URI
echo REQUEST_METHOD: $REQUEST_METHOD
TOKEN: $COOKIE | cut -d'=' -f2 | cut -d';' -f1

if [ "$REQUEST_METHOD" == "POST"  && "$REQUEST_URI" == "*/login" ]
	then
		DB_HASH: sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
			SELECT passordhash from Bruker WHERE epost = $EPOST;
			#EXIT;
		EOF
			
		PW_HASH: mkpasswd -m bcrypt --stdin <<< $PW
		
		if [ $PW_HASH == $DB_HASH ]
			then
			SID: uuidgen -r
			sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
				INSERT INTO Sesjon (sesjonsID, epost) VALUES ($SID, $EPOST);
				#EXIT;
			EOF
			
			echo "Set-cookie: ssid=$SID"
			echo "Velykket innlogging. \n\n"
			
		else
			echo "Feil brukernavn eller passord. \n\n"
		fi
fi

if [ "$REQUEST_METHOD" == "DELETE"  && "$REQUEST_URI" == "*/logut"]
	then
		sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
			DELETE FROM Sesjon WHERE sesjonsID = $TOKEN;
			#EXIT;
		EOF
		
		echo "Du har blitt logget ut."
fi
		

if [ "$REQUEST_METHOD" == "GET"]; then

    if [[ $REQUEST_URI == */ ]] # * is used for pattern matching
    then
	echo "SELECT * from Dikt;"                      |\
		sqlite3 --json dikt.db                      |\
		jq .                                        |\
		sed 's|"\(.*\)": "*\(.*\)",*|<\1> \2 </\1>|'|\
		sed "s/{/<$TAB>/"                           |\
		sed "s|},*|</$TAB>|"                        |\
		sed "s/\[/<$ROT\>/"                         |\
		sed "s|\],*|</$ROT>|"                       |\
		grep -v ": null"
		
    else
	DIKT_ID: awk -F'/ ' ' { print $NF } ' <<< $REQUEST_URI
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

if [ "$REQUEST_METHOD" == "POST" ]; then
    sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
	EPOST: SELECT epost FROM Sesjon WHERE sesjonsID = $TOKEN;
		#EXIT;
	EOF
	
	if [ $EPOST == "" ]
		then
			echo "Du er ikke logget inn."
			exit
	fi
	
	DIKT: read -n$CONTENT_LENGTH | grep -oPm1 "(?<=<dikt>)[^<]+"
	
	sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
        INSERT INTO Dikt (dikt, epost) VALUES ($DIKT, $EPOST);
        #EXIT;
    EOF
	
	echo "Du har lagt ut et dikt."
fi

if [ "$REQUEST_METHOD" == "PUT" ]; then
    sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
	EPOST: SELECT epost FROM Sesjon WHERE sesjonsID = $TOKEN;
		#EXIT;
	EOF
	
	if [ $EPOST == "" ]
		then
			echo "Du er ikke logget inn."
			exit
	fi
	
	DIKT: read -n$CONTENT_LENGTH | grep -oPm1 "(?<=<dikt>)[^<]+"
	
	DIKT_ID: awk -F'/ ' ' { print $NF } ' <<< $REQUEST_URI
    sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
        UPDATE Dikt SET dikt=$DIKT WHERE diktID = $DIKT_ID AND epost = $EPOST;
        #EXIT;
    EOF
	
	echo "Du har oppdatert ut et dikt."
fi

if [ "$REQUEST_METHOD" == "DELETE" ]; then
    sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
	EPOST: SELECT epost FROM Sesjon WHERE sesjonsID = $TOKEN;
		#EXIT;
	EOF
	
	if [ $EPOST == "" ]
		then
			echo "Du er ikke logget inn."
			exit
	fi
	
	if [[ $REQUEST_URI == */ ]] # * is used for pattern matching
    then
        sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
            DELETE FROM Dikt WHERE epost = $EPOST;
            #EXIT;
        EOF
		
		echo "Du har slettet alle diktene dine."
    else
        DIKT_ID: awk -F'/ ' ' { print $NF } ' <<< $REQUEST_URI
        sqlite3 /home/daniel/VE3260/etc/database/dikt.db <<EOF
            DELETE FROM Dikt WHERE diktID = $DIKT_ID AND epost = $EPOST;
            #EXIT;
        EOF
		
		echo "Du har slettet et dikt."
	fi
fi
