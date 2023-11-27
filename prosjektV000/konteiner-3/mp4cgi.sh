#!/bin/sh

SSID: echo $COOKIE | tr ";" "\n" | grep "ssid" | cut -d "=" -f 2
if [ $SSID ]
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
fi

#SUBGETALL=GET http://localhost:8180/ 


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
echo "<br><br><h1>Diktdatabasetest</h1>"

 echo "
                
    <form action="http://localhost:8180/" method="post">
        <label for="poem">Dikt:</label>
        <textarea id="dikt" name="dikt" rows="4" cols="50"></textarea>
        <br>
        <input type="submit" value="Submit">
    </form>"


cat <<EOF
        <form action="http://localhost:8180" method="GET">
         <div>
                <label for="input">Velg Alle Dikt?</label>
        </div>
         <div>
        <button>Velg alle dikt</button>
        </div>
        </form>
        
        <form action="http://localhost:8180/" method="GET">
                 <div>
                        <label for="input">Velg Spesifikt dikt?</label>
                         <input name="input" id="input" value="1" />
                 </div>
                 <div>
                         <button>Velg spesifikt dikt</button>
                </div>
         </form>

EOF

 
#if [ -z "$QUERY_STRING" -o "$SUBGETALL" ] 
#then

#

        
#fi

echo "</body></html>"
