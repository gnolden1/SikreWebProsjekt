#!/bin/bash


#sudo docker stop konteiner1
#sudo docker stop konteiner2
#sudo docker stop konteiner3

#sudo docker rm konteiner1
#sudo docker rm konteiner2
#sudo docker rm konteiner3

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker image rm $(sudo docker images)

#sudo docker compose down
#kan også sudo docker konteiner2 down feks
