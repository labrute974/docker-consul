# Consul in Docker cluster

This repo contains the build for a **consul** docker image.

This image allows you to create a consul server on top of a single docker host, or to run it in a [docker swarm](https://docs.docker.com/swarm/)

This readme will take you through steps on how to run **Consul** in a single container on a single **docker host**.


The project has been highly inspired by the progrium/consul image.

## Pre requisites

This document utilises different technologies to do the job.

You would need to install on your local machine:

  - [Docker](https://docs.docker.com/installation/mac/)
  - [Docker Machine](https://docs.docker.com/machine/install-machine/)
  - [Virtualbox](https://www.virtualbox.org/wiki/Downloads)

## Single Consul container on a single host

First of all, let's create a docker host first:

    docker-machine create --driver virtualbox local
    # load docker host variables
    eval $(docker-machine env local)

Let's now build the image:

    # you can build the image with:
    docker build . -t labrute974/consul

    # or you can just pull the image from docker:
    docker pull labrute974/consul

The image comes with a tool **cmd:build** that allows you to generate the docker command to run to deploy your consul container:

    docker run --rm labrute974/consul cmd:build $(docker-machine ip local):server -d
    # output:
    Execute the following command to create the instance:
      docker run -p 192.168.99.100:8300:8300 -p 192.168.99.100:8301:8301 -p 192.168.99.100:8301:8301/udp -p 192.168.99.100:8302:8302 -p 192.168.99.100:8302:8302/udp -p 192.168.99.100:8400:8400 -p 192.168.99.100:8500:8500 -p 192.168.99.100:53:53 -p 192.168.99.100:53:53/udp  labrute974/consul -server -advertise 192.168.99.100


