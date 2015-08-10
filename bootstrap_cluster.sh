#! /bin/bash

set -e

TOKEN=$(docker-swarm create)

## Create the docker machines
echo " - Creating the docker hosts"
docker-machine create --driver virtualbox --swarm --swarm-master --swarm-discovery token://$TOKEN swarm-master
docker-machine create --driver virtualbox --swarm --swarm-discovery token://$TOKEN swarm-node00
docker-machine create --driver virtualbox --swarm --swarm-discovery token://$TOKEN swarm-node01

eval "$(docker-machine env --swarm swarm-master)"

echo " - Pulling the labrute974/consul image on all docker hosts"
docker pull labrute974/consul

echo " - Creating first consul container"
eval "$(NAME=consul01; docker run -e affinity:container!=consul* --name ${NAME}-setup --net=host labrute974/consul cmd:build eth1:server -d --name $NAME -h $NAME -e affinity:container==${NAME}-setup)"

echo " - Creating second consul container"
eval "$(NAME=consul02; docker run -e affinity:container!=consul* --name ${NAME}-setup \
    --net=host labrute974/consul cmd:build \
    eth1:server:$(docker inspect -f '{{.Node.IP}}' consul01) \
    -d --name $NAME -h $NAME -e affinity:container==${NAME}-setup)"

echo " - Creating third consul container"
eval "$(NAME=consul03; docker run -e affinity:container!=consul* --name ${NAME}-setup \
    --net=host labrute974/consul cmd:build \
    eth1:server:$(docker inspect -f '{{.Node.IP}}' consul01) \
    -d --name $NAME -h $NAME -e affinity:container==${NAME}-setup)"

docker rm consul01-setup consul02-setup consul03-setup

echo "You can connect on the consul cluster here: http://$(docker inspect -f '{{.Node.IP}}' consul01):8500/"
