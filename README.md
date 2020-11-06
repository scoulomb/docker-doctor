

docker run -it --entrypoint /bin/sh <imagee>



# we use ubuntu as base image because we can not run traceroute with busybox when not root

docker build . -f customUbuntu.Dockerfile -t customubuntu


https://stackoverflow.com/questions/34198392/docker-official-registry-docker-hub-url


# Tests


-> Timeout, it can be a network policy, firewall issue
To know the root cause, I need to perform a traceroute.

## Test a traecroute with Ubuntu 

### How to a traceroute when not root?

Traceroute is usually not working when not root which is our case due to psp/scc on the cluster.
From this article and Stackoverflow question below: the tip is to run it from ubuntu and install traceroute manually.
- Doc 1: [Stackoverflow: Question on traceroute whe not root](https://stackoverflow.com/questions/61043365/operation-not-permitted-when-performing-a-traceroute-from-a-container-deployed-i/61396011?noredirect=1#comment108753492_61396011)
- Doc 2: [Run traceroute from ubuntu when not root](https://github.com/scoulomb/myk8s/blob/master/Security/0-capabilities-bis-part1-basic.md#side-note-based-on-so-answer)

### Do it

#### Bake a new image with traceroute and netcat

We have to make the image to install traceroute (as needs to be root to do it).
Cannot do live `apt install`  as in doc1, thus as proposed in doc2 we will bake a new image.
 

### Run command and get investigation results

Output is:


````buildoutcfg

````

I can not curl.
But the traceroute results show there is not ip range clash anymore. This is an excellent news!

If we do nc?

````buildoutcfg

$ nc -vz -w

````




### Going further 

To confirm this we could use a TCP traceroute.

Traceroute uses ICMP, so not port. However in Linux it is UDP by default. 
But we can  force to do a TCP traceroute and specify the port.
If it does not work it confirms it is a firewall issue/network policy issue

However if we cheat to perform a standard traceroute this is not possible:

````buildoutcfg

````

ping uses icmp, it has same issue with capabilities.
Traceroute provides more details.