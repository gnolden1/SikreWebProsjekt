#!/bin/sh

TOKEN=$(echo $HTTP_COOKIE | sed 's|.*ssid=\(.*\).*|\1|')
if [ $TOKEN ]
then
        LOGIN=TRUE
else
        LOGIN=FALSE
fi

SUBLOGIN=$(echo $QUERY_STRING | tr "&" "\n" | grep "subLogin")
if [ $SUBLOGIN ]
then
        LOGIN=TRUE
fi

SUBLOGOUT=$(echo $QUERY_STRING | tr "&" "\n" | grep "subLogout")
if [ $SUBLOGOUT ]
then
        LOGIN=FALSE
        curl -b ssid=$TOKEN -X DELETE konteiner2/logout > /dev/null
        echo "Set-Cookie: ssid=deleted; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT"
fi

TOKEN=$(echo $HTTP_COOKIE | sed 's|.*ssid=\(.*\).*|\1|')
if [ $TOKEN ]
then
        LOGIN=TRUE
else
        LOGIN=FALSE
fi

SLETT=$(echo $QUERY_STRING | tr "&" "\n" | grep "DELETE")

if [ $SLETT ]
then
        ID=$(echo $SLETT | cut -d "=" -f 2)
        curl -b ssid=$TOKEN -X DELETE konteiner2/$ID > /dev/null

fi


REDIGER=$(echo $QUERY_STRING | tr "&" "\n" | grep "PUT")

if [ $REDIGER ]
then
        ID=$(echo $REDIGER | cut -d "=" -f 2)
        TEKSTSTRENG=$(echo $QUERY_STRING | tr "&" "\n" | grep "Tekstredigering" | cut -d "=" -f 2)
        curl -b ssid=$TOKEN -X PUT konteiner2/$ID -d "$TEKSTSTRENG" > /dev/null
fi



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
                <form>                                                  \
                        <label for="subLogout">Log out: </label>        \
                        <input type="submit" name="subLogout">          \
                </form>"
else
        echo "  <p>You are not logged in</p>                                    \
                 <form action="http://localhost:8180/login" method="post" enctype="text/plain" > 
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


 echo "

    <form action="http://localhost:8180/" method="post" enctype="text/plain">
        <label for="poem">Dikt:</label>
        <textarea id="dikt" name="dikt" placeholder="Dikt" rows="15" cols="50"></textarea>
        <br>
        <input type="submit" value="Submit">
    </form>"



cat <<EOF
        <form action="http://localhost:8180" method="GET">
         <div>
       <br><br> <button>Velg alle dikt</button><br><br>
        </div>
        </form>



         <form action="http://localhost:8180" method="GET">
                 <div>
                        <input type="submit" formaction="http://localhost:8080" formmethod="get" name="DELETE" value="">Slettalt
                </div>
        </form>


EOF

#echo "$ID"
echo "$REDIGER"



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

I=curl --silent konteiner2 | grep "diktID" | sed 's|.*>\(.*\)<.*|\1|'

for i in $(curl --silent konteiner2 | grep "diktID" | sed 's|.*>\(.*\)<.*|\1|')
do
   echo "
        <tr>
        <td>

           <form action="http://localhost:8180/$i" method="post" enctype="text/plain">
                <label for="poem">Dikt $i:</label>
                <br>



                <input type="submit" formethod="put" value="Endre" enctype="text/plain">
                <input type="submit" formmethod="get" value="Hent">
                <input type="submit" formaction="http://localhost:8080" formmethod="get" name="DELETE" value="$i">Slett




           </form>
        <label for=rediger>Dikt:</label>
        <text area placeholder="EndreDikt" id="PUT" type="submit" rows="30" cols="30" formaction="http://localhost:8080" formmethod="get" name="PUT" value="$i">Rediger</text area><>


    <form action=http://localhost:8080/ method=get>
        <label for=poem>Dikt $i:</label>
        <textarea id=dikt name="Tekstredigering" placeholder=Rediger rows=15 cols=50></textarea>
        <br>
        <input type="submit" formaction="http://localhost:8080" formmethod="get" name="PUT" value="$i" enctype="text/plain">Rediger


    </form>


        <a href="localhost:8180/$i">Dikt nummer $i</a>

        </td>
        </tr>
"

done

</table>








if [ "$QUERY_STRING" -o "$SUBGETALL" ]
then




#


#fi

echo "</body></html>"


