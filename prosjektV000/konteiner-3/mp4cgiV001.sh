#!/bin/sh
#Current versjon
BODY=$(tail -c $CONTENT_LENGTH | tr -d "\r")

TOKEN=$(echo $HTTP_COOKIE | sed 's|.*ssid=\(.*\).*|\1|')
if [ "$TOKEN" ]
then
        LOGIN=TRUE
else
        LOGIN=FALSE
fi

SUBLOGIN=$(echo $BODY | grep "subLogin")
if [ "$SUBLOGIN" ]
then
        USERNAME=$(echo $BODY | tr "&" "\n" | grep inUsername | cut -d "=" -f 2)
        PASSWORD=$(echo $BODY | tr "&" "\n" | grep inPassword | cut -d "=" -f 2)

        COOKIEJAR=/usr/local/apache2/cgi-bin/cookiejar
        touch $COOKIEJAR
        RESPONSE=$(curl -X POST -d "<Bruker><epost>$USERNAME</epost><passord>$PASSWORD</passord></Bruker>" konteiner2/login --silent -c $COOKIEJAR)
        if [ "$RESPONSE" = "SUCCESS" ]
        then
                LOGIN=TRUE
                NEWSID=$(cat $COOKIEJAR | grep ssid | tr "\t" " " | cut -d " " -f 7)
                echo "Set-Cookie: ssid=$NEWSID; Path=/; Max-Age: 3600;"
        fi
        rm $COOKIEJAR
fi


SUBLOGOUT=$(echo $BODY | grep "subLogout")
if [ "$SUBLOGOUT" ]
then
        LOGIN=FALSE
        curl -b ssid=$TOKEN -X DELETE konteiner2/logout > /dev/null
        echo "Set-Cookie: ssid=deleted; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT"
fi

SLETT=$(echo $BODY | grep "DELETE")
if [ "$SLETT" ]
then
        ID=$(echo $SLETT | cut -d "=" -f 2 | head -c 1)

        curl -b ssid=$TOKEN -X DELETE konteiner2/$ID > /dev/null
fi


REDIGER=$(echo $BODY | grep "PUT")
if [ "$REDIGER" ]
then
        ID=$(echo $REDIGER | cut -d "=" -f 3 | head -c 1)
        TEKSTSTRENG=$(echo $REDIGER | cut -d "=" -f 2 | cut -d "PUT=" -f 1)
        curl -b ssid=$TOKEN -X PUT konteiner2/$ID -d "$TEKSTSTRENG" > /dev/null
fi


SUBMIT=$(echo $BODY | grep "POST")
if [ "$SUBMIT" ]
then

        TEKST=$(echo $SUBMIT | cut -d "=" -f 2)
        curl -b ssid=$TOKEN -X POST konteiner2/ -d "<dikt>$TEKST</dikt>" > /dev/null
fi


#Bør implementere Universell og Valgfri Geting fra bruker

echo "Content-type:text/html;charset=utf-8"

echo

cat << EOF
<!doctype html>
<html>
        <head>
                <meta charset="utf-8">
                <title>mp4</title>
                <link rel="stylesheet" href="http://localhost:80/stil.css">
        </head>
        <body>


EOF

if [ "$LOGIN" = "TRUE" ]
then
        echo "  <p>You are logged in</p><br>                            \
                <form method="post">                                                  \
                        <label for="subLogout">Log out: </label>        \
                        <input type="submit" name="subLogout">          \
                </form>"
else
        echo "  <p>You are not logged in</p>                                    \
                 <form action="http://localhost:8080/" method="post"> 
                        <label for="inUsername">Username:</label>               \
                        <input type="text" name="inUsername"></input><br><br>   \
                        <label for="inPassword">Password:</label>               \
                        <input type="text" name="inPassword"></input><br><br>   \
                        <label for="subLogin">Log in: </label>                  \
                        <input type="submit" name="subLogin">                   \
                </form>"
fi
echo "<a href="http://localhost:80/index.html">Link to mp2-nettsiden</a>"
echo "<br><br><h1>Diktdatase Input</h1>"

#echo $TEKST
#echo $SUBMIT

#POST
 echo "

    <form action="http://localhost:8080/" method="post" enctype="text/plain">
        <label for="poem">Dikt:</label>
        <textarea id="dikt" name="POST" placeholder="Dikt" rows="15" cols="50"></textarea>
        <br>
        <input type="submit" value="Submit">
    </form>"



cat <<EOF
        <form action="http://localhost:8080" method="POST">
         <div>
       <br><br> <button>Velg alle dikt</button><br><br>
        </div>
        </form>



         <form action="http://localhost:8080" method="POST">
                 <div>
                        <input type="submit" formaction="http://localhost:8080" formmethod="post" name="DELETE" value="">Slettalt
                </div>
        </form>


EOF

#echo "$ID"
echo "$TEKSTSTRENG"
echo "$ID"



echo "

        <style>
        table, th, td {
        margin-left: auto;  
        margin-right: auto; 
        }
        </style>

        <table>
       "

#echo $(curl --silent konteiner2 | grep "diktID" | sed 's|.*>\(.*\)<.*|\1|')

#I=curl --silent konteiner2 | grep "diktID" | sed 's|.*>\(.*\)<.*|\1|'

for i in $(curl --silent konteiner2 | grep "diktID" | sed 's|.*>\(.*\)<.*|\1|')
do
   echo "
        <tr>
        <td>

           <form action="http://localhost:8080/$i" method="post" enctype="text/plain">
                <label for="poem">Dikt $i:</label>
                <br>



                <input type="submit" formethod="put" value="Endre" enctype="text/plain">
                <input type="submit" formmethod="post" value="Hent">
                <input type="submit" formaction="http://localhost:8080" formmethod="post" name="DELETE" value="$i" enctype="text/plain">Slett




           </form>
        <label for=rediger>Dikt:</label>
        <text area placeholder="EndreDikt" id="PUT" type="submit"  rows="30" cols="30" name="PUT" value="$i">Rediger</text area><>




    <form action=http://localhost:8080/ method=post enctype="text/plain">
        <label for=poem>Dikt $i:</label>
        <textarea id="dikt" name="Tekstredigering" placeholder="Rediger" rows=15 cols=50>

"
        echo "$( curl --silent konteiner2/$i | xmllint --xpath '//dikt/text()' - )
"

echo "

        </textarea>
        <br>
        <input type="submit" formaction="http://localhost:8080/" formmethod="post" name="PUT" value="$i" enctype="text/plain">Rediger


    </form>


        <a href="localhost:8180/$i">Dikt nummer $i</a>

        </td>
        </tr>


        </table>
"

done





echo "</body></html>"


