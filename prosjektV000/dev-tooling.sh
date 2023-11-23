#!/bin/bash

#siden vi skal ha portability ift deplojering tenker jeg det er smart også
#ift dev tooling

sudo apt install gcc
sudo apt install net-tools
sudo apt update

# For å kjøre mp1/2 webserveren uten container må man ha en bruker på systemet som heter "webserver"
