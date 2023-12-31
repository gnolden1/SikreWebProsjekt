#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
	  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	           
sudo apt-get update
#install docker-compose
sudo apt install gcc
sudo apt install net-tools
sudo apt-get install docker-compose-plugin	
sudo apt-get update
add user webserver
sudo cp daemon.json /etc/docker/daemon.json
systemctl docker restart
docker build . -t konteiner1

