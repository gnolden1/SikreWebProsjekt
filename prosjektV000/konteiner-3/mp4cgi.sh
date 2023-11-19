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

echo "Content-Type: text/html"
echo "Set-Cookie: test=true"

echo

cat << EOF
<!doctype html>
<html>
        <head>
                <meta charset="utf-8">
                <title>mp4</title>
        </head>
        <body>
EOF
if [ $LOGIN = "TRUE" ]
then
        echo "  <p>You are logged in</p><br>                            \
                <form>                                                  \
                        <label for="subLogout">Log out: </label>        \
                        <input type="submit" name="subLogout">          \
                </form>"
else
        echo "  <p>You are not logged in</p>                                    \
                <form>                                                          \
                        <label for="inUsername">Username:</label>               \
                        <input type="text" name="inUsername"></input><br><br>   \
                        <label for="inPassword">Password:</label>               \
                        <input type="text" name="inPassword"></input><br><br>   \
                        <label for="subLogin">Log in: </label>                  \
                        <input type="submit" name="subLogin">                   \
                </form>"
fi
echo "<br><br><h1>Diktdatabasetest</h1>"

if [ (-z $QUERY_STRING) -o ($SUBGETALL) ]
then
        # make table of all poems
fi

echo "</body></html>"
