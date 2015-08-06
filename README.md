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
  - [Docker Swarm](http://docs.docker.com/swarm/install-w-machine/)
  - [Virtualbox](https://www.virtualbox.org/wiki/Downloads)

## Single Consul container on a single host

First of all, let's create a docker host first:

    $ docker-machine create --driver virtualbox local
    # load docker host variables
    $ eval $(docker-machine env local)

Let's now build the image:

    # you can build the image with:
    $ docker build . -t labrute974/consul

    # or you can just pull the image from docker:
    $ docker pull labrute974/consul

The image comes with a tool **cmd:build** that allows you to generate the docker command to run to deploy your consul container:

    $ docker run --rm labrute974/consul cmd:build $(docker-machine ip local):server -d
    # example output:
    Execute the following command to create the instance:

      docker run -p 192.168.99.100:8300:8300 -p 192.168.99.100:8301:8301 -p 192.168.99.100:8301:8301/udp -p 192.168.99.100:8302:8302 -p 192.168.99.100:8302:8302/udp -p 192.168.99.100:8400:8400 -p 192.168.99.100:8500:8500 -p 192.168.99.100:53:53 -p 192.168.99.100:53:53/udp  labrute974/consul -server -advertise 192.168.99.100


Once you run that command, you will be able to access the **Consul UI** through the IP that is you can see in the output on port 8400.

## Consul cluster on swarm

Here we will see how to install a consul cluster on top of [Docker Swarm](https://docs.docker.com/swarm/).

### Creation of the swarm cluster

Let's first create our **swarm cluster** with 3 nodes:

    ## Create a token for the swarm cluster
    $ TOKEN=$(docker-swarm create)

    ## Create a master node for the swarm cluster
    $ docker-machine create --driver virtualbox --swarm --swarm-master --swarm-discovery token://$TOKEN swarm-master

    ## Then create two nodes to add to the cluster
    $ docker-machine create --driver virtualbox --swarm --swarm-discovery token://$TOKEN swarm-node00
    $ docker-machine create --driver virtualbox --swarm --swarm-discovery token://$TOKEN swarm-node01

    ## List the docker hosts
    $ docker-machine ls

Note that when using the token discovery method for **swarm**, the node list is found on https://discovery-stage.hub.docker.com/v1/clusters/<token>.

This means that you need internet to be able to create a swarm cluster using the token method.

There's several other ways to do swarm node discovery. You could use a flat file, or even use a **Consul service** (maybe the first one we created above!).

You can verify your cluster by using:

    $ docker-swarm list token://$TOKEN

The output should contain 3 IPs, the IPs of the docker hosts.

### Creation of the consul cluster

How about we verify our **swarm cluster** first?

    ## connect on the docker swarm API
    $ eval "$(docker-machine env --swarm swarm-master)"

    ## you can get information about your swarm cluster by running
    $ docker info

When running `docker info`, you'll see that it lists 4 containers in the cluster.

But ... how weird ... when you type `docker ps`, you don't see any containers ... what?!

That's because **swarm api** will hide the swarm containers that hold the cluster together.

You can see them by using `docker ps -a`.



Let's now create our first **consul service** on the **swarm cluster**:

    ## let's pull the consul image
    $ docker pull labrute974/consul
    # you can see here that the images is getting pulled on each node of the swarm cluster

    
    ## build the command to run to create the service
    $ NAME="consul01"; docker run -e affinity:container!=consul* --name ${NAME}-setup --net=host labrute974/consul cmd:build eth1:server -d --name $NAME -h $NAME -e affinity:container==${NAME}-setup
    # example output:
    Execute the following command to create the instance:

      docker run -p 192.168.99.108:8300:8300 -p 192.168.99.108:8301:8301 -p 192.168.99.108:8301:8301/udp -p 192.168.99.108:8302:8302 -p 192.168.99.108:8302:8302/udp -p 192.168.99.108:8400:8400 -p 192.168.99.108:8500:8500 -p 192.168.99.108:53:53 -p 192.168.99.108:53:53/udp -d --name consul01 -e affinity:container==consul01-setup labrute974/consul -server -advertise 192.168.99.108

Now that's interesting. Compared to the way to run the `cmd:build` command from the consul service on a single host, we added a few options here.

We have `-e affinity:container!=consul*` allows us to start our build command container on any host in our Docker swarm that doesn't have any container which names start with **consul**.

We also use `--net=host` to let the container use the host network.

The reason for it is for the `cmd:build` to be able to find the IP of the host on which the container has been created, as the container can be started on any host of the cluster so we don't know in advance which IP should be used to advertise the **consul** service on.

`eth1` basically tells `cmd:build` to get the IP from the interface **eth1**.

You can now delete the setup consul container:

    $ docker rm -f consul01-setup


Now, if we look at the end of the command we can see: `-d --name consul01 -e affinity:container==consul01-setup`. Those are **docker** options that will be passed to the command that `cmd:build` will generate.

Here we say that when we run the generated command, we want the container to be started on a host that already has container named **consul01-setup** on it.
That allows us to make sure that we deploy on the host with the right IP that we want to advertise the **Consul service** on.

If we don't specify which IP to advertise on, by default **Consul** advertise on the first private IP it finds, but the container IP is not routable across hosts.


Once that's done, let's create the second and third **Consul** containers:

    $ NAME=consul02; docker run -e affinity:container!=consul* --name ${NAME}-setup \
        --net=host labrute974/consul cmd:build \
        eth1:server:$(docker inspect -f '{{.Node.IP}}' consul01) \
        -d --name $NAME -h $NAME -e affinity:container==${NAME}-setup
    # run the command returned

    $ NAME=consul03; docker run -e affinity:container!=consul* --name ${NAME}-setup \
        --net=host labrute974/consul cmd:build \
        eth1:server:$(docker inspect -f '{{.Node.IP}}' consul01) \
        -d --name $NAME -h $NAME -e affinity:container==${NAME}-setup
    # run the command returned

    $ docker rm consul02-setup consul03-setup

You can see here that we have a third field in the argument for `cmd:build`: `eth1:server:$(docker inspect -f '{{.Node.IP}}' consul01)`.

This is the IP of the **Consul** cluster to join. Basically here, it's the IP of the first consul service we've created.



### Test & Conclusion

You can now connect on the **consul cluster** by using one of the docker host IPs on port 8500.

You can run `docker-machine ls` to find the IPs to connect to.

Enjoy!

## TODO

- Find a way to make the swarm master highly available
- Generate certs for the swarm containers to map them to the name of the **Docker host** rather than its IP, as Virtualbox doesn't set static IPs by default to its VMs.
