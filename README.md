# Docker doctor

## Objective

Tool to diagnose network issue when we can not run a container as root in a given Kubernetes cluster.
This requires the permission to create a pod in a namespace.

We baked our own image, because `busybox` (among others) does not accept `traceroute` when not allowed to run a container as root.
This is the case  in many situations (and is configured with psp/scc by cluster admin).
Also base image like Python have minimal setup and thus does not have those tools available.

From this article and Stackoverflow question below: the tip is to run it from ubuntu and install traceroute manually.
- Doc 1: [Stackoverflow: Question on traceroute whe not root](https://stackoverflow.com/questions/61043365/operation-not-permitted-when-performing-a-traceroute-from-a-container-deployed-i/61396011?noredirect=1#comment108753492_61396011)
- Doc 2: [Run traceroute from ubuntu when not root](https://github.com/scoulomb/myk8s/blob/master/Security/0-capabilities-bis-part1-basic.md#side-note-based-on-so-answer)

We also added other network tools (ping, nc, curl...).

## Build & run & push

<!--
````shell script
ssh <somewhere-where-can-build-without-signature-issue> # HP
git clone/pull
````
-->

````shell script
sudo docker build . -t docker-doctor
sudo docker run -it --entrypoint /bin/sh docker-doctor # for test
# https://hub.docker.com/repository/docker/scoulomb/docker-doctor
sudo docker login -u scoulomb
sudo docker tag  docker-doctor  scoulomb/docker-doctor:dev
sudo docker push scoulomb/docker-doctor:dev
````

We can also sot he push with Dockerhub build !

**Known issues** 

- Package 404 not found: upgrade to recent version of Ubuntu here: https://hub.docker.com/_/ubuntu?tab=tags


## usage (client) 


**Source**:

- Here I am leveraging knowledge from this pages:
    - https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md
    - https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d-other-applications.md
It is linked directly when relevant.


- Note some cluster/machine requires docker hub full path when pulling.
See more [info](https://stackoverflow.com/questions/34198392/docker-official-registry-docker-hub-url).

### Docker

No need details? go straight to example in [sample.sh](./sample.sh)/

#### Using entrypoint override

````shell script
# rmi in case update and had former version
sudo docker rmi scoulomb/docker-doctor:dev
sudo docker rmi registry.hub.docker.com/scoulomb/docker-doctor:dev
# This will also pull
sudo docker run -it --entrypoint /bin/sh scoulomb/docker-doctor:dev
sudo docker run -it --entrypoint /bin/sh registry.hub.docker.com/scoulomb/docker-doctor:dev # first it will go through artifactory and see all layer there
````
<!--
Pull Output where we can see that in second case it goes the first time through docker and realize it has it in local

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo docker run -it --entrypoint /bin/sh registry.hub.docker.com/scoulomb/docker-doctor:dev
Unable to find image 'registry.hub.docker.com/scoulomb/docker-doctor:dev' locally
dev: Pulling from scoulomb/docker-doctor
Digest: sha256:e25bfd7925c517d21e2ffaaab1b483e42943f8b769f52c3b0a39a4b5361523d0
Status: Downloaded newer image for registry.hub.docker.com/scoulomb/docker-doctor:dev
````
-->

output is 
<!-- ssh if needed before -->

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo docker run -it --entrypoint /bin/sh registry.hub.docker.com/scoulomb/docker-doctor:dev
# echo "hello"
hello
# ping attestationcovid.site
PING attestationcovid.site (216.239.34.21) 56(84) bytes of data.
64 bytes from any-in-2215.1e100.net (216.239.34.21): icmp_seq=1 ttl=115 time=36.6 ms
64 bytes from any-in-2215.1e100.net (216.239.34.21): icmp_seq=2 ttl=115 time=37.2 ms
^C
--- attestationcovid.site ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 36.630/36.922/37.214/0.292 ms
#
````

### Using cmd override

````shell script
sudo docker run -it registry.hub.docker.com/scoulomb/docker-doctor:dev -- /bin/sh
````

Output is 

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo docker run -it registry.hub.docker.com/scoulomb/docker-doctor:dev -- /bin/sh
This keeps container running.
````

It does not work, here args are given to the entrypoint and it is not used.
To make it work we need to reset the entrypoint and give args.
We come back to the example given here: https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md#kubectl-create-job with `sudo docker run alpine /bin/sleep 5`.

````shell script
sudo docker run -it --entrypoint="" registry.hub.docker.com/scoulomb/docker-doctor:dev -- /bin/sh
````

Output is 


````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo docker run -it --entrypoint="" registry.hub.docker.com/scoulomb/docker-doctor:dev /bin/sh
# echo "hello"
hello
#
````

Not that a good practise when using using Kubernetes which is to use `--`, would not work here

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo docker run -it --entrypoint="" registry.hub.docker.com/scoulomb/docker-doctor:dev -- /bin/sh
docker: Error response from daemon: OCI runtime create failed: container_linux.go:349: starting container process caused "exec: \"--\": executable file not found in $PATH": unknown.
ERRO[0000] error waiting for container: context canceled
sylvain@sylvain-hp:~/docker-doctor$
````

Because it is given as args as explained here:
https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md#override-entrypoint-and-command


### And without entrypoint override

````shell script
sudo docker run -d --name doctor1 registry.hub.docker.com/scoulomb/docker-doctor:dev
sudo docker exec -it doctor1 /bin/sh 
````

Output is 

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo docker exec -it doctor1 /bin/sh
# echo "hello"
hello
#
````

### /bin/sh can be replaced by instruction

Everytime we did `/bin/sh`, we can also give a command.

````shell script
#### Using entrypoint override
sudo docker run -it --entrypoint="ping attestationcovid.site"  registry.hub.docker.com/scoulomb/docker-doctor:dev
sudo docker run -it --entrypoint="ping"  registry.hub.docker.com/scoulomb/docker-doctor:dev attestationcovid.site
### Using cmd override
 sudo docker run -it --entrypoint="" registry.hub.docker.com/scoulomb/docker-doctor:dev ping attestationcovid.site
### And without entrypoint override
sudo docker exec -it doctor1 ping attestationcovid.site
````

Output is 

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo docker run -it --entrypoint="ping attestationcovid.site"  registry.hub.docker.com/scoulomb/docker-doctor:dev
docker: Error response from daemon: OCI runtime create failed: container_linux.go:349: starting container process caused "exec: \"ping attestationcovid.site\": executable file not found in $PATH": unknown.
ERRO[0000] error waiting for container: context canceled
sylvain@sylvain-hp:~/docker-doctor$ sudo docker run -it --entrypoint="ping"  registry.hub.docker.com/scoulomb/docker-doctor:dev attestationcovid.site
PING attestationcovid.site (216.239.32.21) 56(84) bytes of data.
64 bytes from any-in-2015.1e100.net (216.239.32.21): icmp_seq=1 ttl=114 time=37.5 ms
^C
--- attestationcovid.site ping statistics ---
2 packets transmitted, 1 received, 50% packet loss, time 1001ms
rtt min/avg/max/mdev = 37.516/37.516/37.516/0.000 ms
sylvain@sylvain-hp:~/docker-doctor$  sudo docker run -it --entrypoint="" registry.hub.docker.com/scoulomb/docker-doctor:dev ping attestationcovid.site
PING attestationcovid.site (216.239.38.21) 56(84) bytes of data.
64 bytes from any-in-2615.1e100.net (216.239.38.21): icmp_seq=1 ttl=114 time=36.1 ms
64 bytes from any-in-2615.1e100.net (216.239.38.21): icmp_seq=2 ttl=114 time=37.2 ms
^C
--- attestationcovid.site ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 36.142/36.688/37.235/0.546 ms
sylvain@sylvain-hp:~/docker-doctor$ sudo docker exec -it doctor1 ping attestationcovid.site
PING attestationcovid.site (216.239.36.21) 56(84) bytes of data.
64 bytes from any-in-2415.1e100.net (216.239.36.21): icmp_seq=1 ttl=114 time=36.5 ms
64 bytes from any-in-2415.1e100.net (216.239.36.21): icmp_seq=2 ttl=114 time=36.2 ms
^C
--- attestationcovid.site ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 36.228/36.384/36.541/0.156 ms
sylvain@sylvain-hp:~/docker-doctor$
````

We can see that for "Using entrypoint override" when we give parameters to entrypoint (which we can do in the Dockerfile), that it is not working with the CLI (at least easily)
We had met same issue [here](https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d-other-applications.md#assume-we-have-in-openshift-templatehelm).


### Kubernetes

This is useful to test connectivity between a docker running inside a pod in your cluster to outside.
Depending on your kube-config it will send you to the right cluster (it depends on your machine/user).
See this doc: https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/kube-config.md] for more details.
On minikube it is setup for you ([oc client, see below](#i-am-using-openshift-cli) does the same).

See here for `kubectl run` deep dive: https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/0-kubectl-run-explained.md

Note": use [imagePullPolicy](https://kubernetes.io/docs/concepts/containers/images/) to always if updated a version several time with same tag,
otherwise if not present will apply by default. In that case when an image with a given tag is in local it will not get the remote update if any.
(same issue we had in docker when did `docker rmi`).

#### Using Docker entrypoint (<=> k8s command) override

````shell script
sudo kubectl run -it docker-doctor-dev-docker-ep-override \
--image=registry.hub.docker.com/scoulomb/docker-doctor:dev \
--restart=OnFailure \
--image-pull-policy=Always \
--command /bin/sh
````

Output is

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo kubectl run -it docker-doctor-dev-docker-ep-override \
> --image=registry.hub.docker.com/scoulomb/docker-doctor:dev \
> --restart=OnFailure \
> --image-pull-policy=Always \
> --command /bin/sh
If you don't see a command prompt, try pressing enter.

# echo "hello"
hello
# ping attestationcovid.site
PING attestationcovid.site (216.239.38.21) 56(84) bytes of data.
64 bytes from any-in-2615.1e100.net (216.239.38.21): icmp_seq=1 ttl=114 time=36.7 ms
64 bytes from any-in-2615.1e100.net (216.239.38.21): icmp_seq=2 ttl=114 time=36.2 ms
^C
--- attestationcovid.site ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 36.213/36.461/36.709/0.248 ms
````

Here is the explanation why we override entrypoint when doing `--command`:
https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md#kubectl-run

### Using docker CMD (<=> k8s args) override 


````shell script
sudo kubectl run -it docker-doctor-dev-docker-cmd-override \
--image=registry.hub.docker.com/scoulomb/docker-doctor:dev \
--restart=OnFailure \
--image-pull-policy=Always \
/bin/sh
````

It will not work because we need to reset the entrpoint as with docker [cli](#using-cmd-override).
But it is not possible: quoting https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md#kubectl-run
>> We can not mix command and args with kubectl.


<!-- it is calling the script with args which lead to weird res ok -->

### And without entrypoint override (k run)

````shell script
sudo kubectl run docker-doc-dev-no-override --image registry.hub.docker.com/scoulomb/docker-doctor:dev --restart=OnFailure --image-pull-policy=Always
sudo kubectl exec -it docker-doc-dev-no-override -- /bin/sh 
````

Output is

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo kubectl run docker-doc-dev-no-override --image registry.hub.docker.com/scoulomb/docker-doctor:dev --restart=OnFailure --image-pull-policy=Always
pod/docker-doc-dev-no-override created
sylvain@sylvain-hp:~/docker-doctor$ sudo kubectl exec -it docker-doc-dev-no-override /bin/sh
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl kubectl exec [POD] -- [COMMAND] instead.
# ^C
#
command terminated with exit code 130
sylvain@sylvain-hp:~/docker-doctor$ sudo kubectl exec -it docker-doc-dev-no-override -- /bin/sh
# echo "hello"
hello
# ping attestationcovid.site
PING attestationcovid.site (216.239.32.21) 56(84) bytes of data.
64 bytes from any-in-2015.1e100.net (216.239.32.21): icmp_seq=1 ttl=114 time=37.4 ms
64 bytes from any-in-2015.1e100.net (216.239.32.21): icmp_seq=2 ttl=114 time=42.0 ms
^C
--- attestationcovid.site ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 37.433/39.701/41.969/2.268 ms
````

Funny part is that here `--` is recommended for `k run`.



### /bin/sh can be replaced by instruction


````shell script
#### Using Docker entrypoint (<=> k8s command) override
````shell script
sudo kubectl run -it docker-doctor-dev-docker-ep-override-direct \
--image=registry.hub.docker.com/scoulomb/docker-doctor:dev \
--restart=OnFailure \
--image-pull-policy=Always \
--command ping attestationcovid.site


### Using docker CMD (<=> k8s args) override 
# N/A

### And without entrypoint override
sudo kubectl exec -it docker-doc-dev-no-override-direct -- ping attestationcovid.site
````


Output is 

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo kubectl run -it docker-doctor-dev-docker-ep-override-direct \
image=regis> --image=registry.hub.docker.com/scoulomb/docker-doctor:dev \
> --restart=OnFailure \
> --image-pull-policy=Always \
> --command ping attestationcovid.site

If you don't see a command prompt, try pressing enter.

64 bytes from any-in-2215.1e100.net (216.239.34.21): icmp_seq=2 ttl=115 time=36.1 ms
64 bytes from any-in-2215.1e100.net (216.239.34.21): icmp_seq=3 ttl=115 time=36.9 ms
64 bytes from any-in-2215.1e100.net (216.239.34.21): icmp_seq=4 ttl=115 time=37.1 ms
^C
--- attestationcovid.site ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 36.128/36.599/37.080/0.391 ms

sylvain@sylvain-hp:~/docker-doctor$ sudo kubectl exec -it docker-doc-dev-no-override -- ping attestationcovid.site
PING attestationcovid.site (216.239.32.21) 56(84) bytes of data.
64 bytes from any-in-2015.1e100.net (216.239.32.21): icmp_seq=1 ttl=114 time=36.7 ms
64 bytes from any-in-2015.1e100.net (216.239.32.21): icmp_seq=2 ttl=114 time=36.6 ms
^C
--- attestationcovid.site ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 36.623/36.670/36.717/0.047 ms
sylvain@sylvain-hp:~/docker-doctor$ sudo kubectl exec -it docker-doc-dev-no-override-direct -- ping attestationcovid.site
````

## Features

For the feature demo I will use the form:  ["without entrypoint override"](#and-without-entrypoint-override-k-run) where I replace /bin/sh by instruction.
````shell script
sudo kubectl run docker-doc-dev --image registry.hub.docker.com/scoulomb/docker-doctor:dev --restart=OnFailure --image-pull-policy=Always

chmod u+x sample.sh
./sample.sh
````

Output would be 

````shell script
sylvain@sylvain-hp:~/docker-doctor$ ./sample.sh
++ sudo kubectl exec -it docker-doc-dev -- nslookup attestationcovid.site
Server:         10.96.0.10
Address:        10.96.0.10#53

Non-authoritative answer:
Name:   attestationcovid.site
Address: 216.239.38.21
Name:   attestationcovid.site
Address: 216.239.34.21
Name:   attestationcovid.site
Address: 216.239.32.21
Name:   attestationcovid.site
Address: 216.239.36.21
Name:   attestationcovid.site
Address: 2001:4860:4802:38::15
Name:   attestationcovid.site
Address: 2001:4860:4802:36::15
Name:   attestationcovid.site
Address: 2001:4860:4802:34::15
Name:   attestationcovid.site
Address: 2001:4860:4802:32::15

++ sudo kubectl exec -it docker-doc-dev -- ping -4 -c 3 attestationcovid.site
PING attestationcovid.site (216.239.38.21) 56(84) bytes of data.
64 bytes from any-in-2615.1e100.net (216.239.38.21): icmp_seq=1 ttl=114 time=37.6 ms
64 bytes from any-in-2615.1e100.net (216.239.38.21): icmp_seq=2 ttl=114 time=36.8 ms
64 bytes from any-in-2615.1e100.net (216.239.38.21): icmp_seq=3 ttl=114 time=36.5 ms

--- attestationcovid.site ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 36.518/36.953/37.592/0.461 ms
++ sudo kubectl exec -it docker-doc-dev -- ping -6 -c 3 attestationcovid.site
ping: connect: Cannot assign requested address
command terminated with exit code 2
++ sudo kubectl exec -it docker-doc-dev -- traceroute attestationcovid.site
traceroute to attestationcovid.site (216.239.34.21), 30 hops max, 60 byte packets
 1  172.17.0.1 (172.17.0.1)  0.040 ms  0.022 ms  0.019 ms
 2  box (192.168.1.1)  0.343 ms  0.407 ms  0.557 ms
 3  1.28.16.109.rev.sfr.net (109.16.28.1)  22.623 ms  23.510 ms  24.013 ms
 4  21.214.96.84.rev.sfr.net (84.96.214.21)  25.436 ms  25.848 ms  27.404 ms
 5  245.213.96.84.rev.sfr.net (84.96.213.245)  28.756 ms  29.152 ms  29.666 ms
 6  157.61.6.109.rev.sfr.net (109.6.61.157)  32.089 ms  28.981 ms  29.396 ms
 7  125.10.136.77.rev.sfr.net (77.136.10.125)  42.313 ms  42.673 ms  43.155 ms
 8  125.10.136.77.rev.sfr.net (77.136.10.125)  43.584 ms  35.999 ms  36.791 ms
 9  74.125.146.198 (74.125.146.198)  37.733 ms  35.396 ms  36.749 ms
10  108.170.244.161 (108.170.244.161)  37.246 ms 108.170.244.193 (108.170.244.193)  35.815 ms 108.170.244.161 (108.170.244.161)  36.627 ms
11  142.250.224.199 (142.250.224.199)  38.570 ms 216.239.48.27 (216.239.48.27)  35.138 ms 108.170.235.37 (108.170.235.37)  36.955 ms
12  any-in-2215.1e100.net (216.239.34.21)  38.189 ms  36.057 ms  35.842 ms
++ sudo kubectl exec -it docker-doc-dev -- nc -vz attestationcovid.site 443
Connection to attestationcovid.site (216.239.32.21) 443 port [tcp/*] succeeded!
++ sudo kubectl exec -it docker-doc-dev -- curl -L attestationcovid.site
++ cut -c-200
<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="title" content="Générateur d'attestation COVID-19 en un click "><meta name="keywords" content="covid19, attestation"><meta name
                                                                                                                                                                                                      </body></html>
````


### Going further 

#### Note on traceroute protocol 

````shell script
On Unix-like operating systems, traceroute sends, by default, a sequence of User Datagram Protocol (UDP) packets, with destination port numbers ranging from 33434 to 33534; the implementations of traceroute shipped with Linux,[2] FreeBSD,[3] NetBSD,[4] OpenBSD,[5] DragonFly BSD,[6] and macOS include an option to use ICMP Echo Request packets (-I), or any arbitrary protocol (-P) such as UDP, TCP using TCP SYN packets, or ICMP.[7]

On Windows, tracert sends ICMP Echo Request packets, rather than the UDP packets traceroute sends by default.[8]
````


#### But we can  force to do a TCP traceroute and specify the port.


````buildoutcfg
sudo kubectl exec -it  docker-doc-dev -- traceroute -T -p 443 attestationcovid.site
````

Outout is 

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo kubectl exec -it  docker-doc-dev -- traceroute -T -p 443 attestationcovid.site
traceroute to attestationcovid.site (216.239.32.21), 30 hops max, 60 byte packets
 1  172.17.0.1 (172.17.0.1)  0.149 ms  0.068 ms  0.061 ms
 2  box (192.168.1.1)  0.522 ms  0.571 ms  0.550 ms
 3  1.28.16.109.rev.sfr.net (109.16.28.1)  21.791 ms  23.220 ms  24.132 ms
 4  21.214.96.84.rev.sfr.net (84.96.214.21)  25.046 ms  25.424 ms  26.798 ms
 5  245.213.96.84.rev.sfr.net (84.96.213.245)  27.705 ms  28.633 ms  29.527 ms
 6  157.61.6.109.rev.sfr.net (109.6.61.157)  31.478 ms  26.226 ms  27.240 ms
 7  * * *
 8  125.10.136.77.rev.sfr.net (77.136.10.125)  42.206 ms  36.269 ms  37.458 ms
 9  74.125.146.198 (74.125.146.198)  37.876 ms  36.671 ms  37.601 ms
10  108.170.244.161 (108.170.244.161)  38.507 ms 108.170.244.193 (108.170.244.193)  35.874 ms 108.170.244.225 (108.170.244.225)  38.003 ms
11  209.85.244.155 (209.85.244.155)  37.468 ms 64.233.175.195 (64.233.175.195)  35.615 ms 64.233.174.93 (64.233.174.93)  36.482 ms
12  any-in-2015.1e100.net (216.239.32.21)  37.511 ms  36.269 ms  36.706 ms
````

#### Requirements

This TCP traceroute with Ubuntu requires to be root and with correct capabilities as UDP traceroute with Alpine. 
Unlike UDP traceroute with Ubuntu which is always working (reason why we did this image).
Please refer to:
- https://github.com/scoulomb/myk8s/pull/2
- https://github.com/scoulomb/myk8s/pull/3
- https://github.com/scoulomb/myk8s/blob/master/Security/0-capabilities-bis-part1-basic.md#part-3-tcp-traceroute

<!-- it is cristal clear now, stop here OK, my my ubuntu refuse -T osef OK --> 

## Notes on image removal 

To avoid the error 

````shell script
$ sudo docker run --name yop -it --entrypoint /bin/sh registry.hub.docker.com/scoulomb/docker-doctor:dev
docker: Error response from daemon: Conflict. The container name "/yop" is already in use by container "55bafd525c61736742dde33c37d7d61eb6d6cc3a73625fd2746d32b71cdc2140". You have to remove (or rename) that container to be able to reuse that name.
$ sudo kubectl run -it docker-doctor-dev-docker-ep-override-rm --image=registry.hub.docker.com/scoulomb/docker-doctor:dev --restart=OnFailure --image-pull-policy=Always --command /bin/sh
Error from server (AlreadyExists): pods "docker-doctor-dev-docker-ep-override-rm" already exists
````

Lot of example here: https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md

Rather than doing 

```shell script
sudo docker rm <image-name> # docker
sudo kubectl delete <po-name> # k8s
```

We can use `--rm` option 

```shell script
sudo docker run --name yop -it --rm --entrypoint /bin/sh registry.hub.docker.com/scoulomb/docker-doctor:dev
```

````shell script
sudo kubectl run -it docker-doctor-dev-docker-ep-override-rm \
--rm \
--image=registry.hub.docker.com/scoulomb/docker-doctor:dev \
--restart=OnFailure \
--image-pull-policy=Always \
--command /bin/sh
````

It may be needed to wait pod deletion.

Note that in Docker it occurs when we give name to the image, which is optional.
Kubernetes can give default name, here it is is based on k8s command

````shell script
sudo kubectl run -it \
--rm \
--image=registry.hub.docker.com/scoulomb/docker-doctor:dev \
--restart=OnFailure \
--image-pull-policy=Always \
--command pouet
````
would create pod

```shell script
pouet                                         0/1     Terminating          0          18s
```

This works only with attached container (`-it`) in docker and kube accepts it but it does not make sense as removed.
So here it would not work in cases "And without entrypoint override"
[Docker](#and-without-entrypoint-override) 
[Kubernetes](#and-without-entrypoint-override-k-run)

## I am using OpenShift CLI 

Which as a consequence does not integrate yet major change of 1.18 kubectl run command of the client.

Replace `sudo kubectl` by `oc`.
 
 <!-- sudo kubectl here is with ssh to ubuntu, not minikube -->
 <!-- sre setup / test.md -->
 
 However this command will launch a job on old version of Kubernetes.
 Explanations and references are avaialable here: https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/0-kubectl-run-explained.md#conclusion
 
 
````shell script
oc run docker-doc-dev --image registry.hub.docker.com/scoulomb/docker-doctor:dev --restart=OnFailure --image-pull-policy=Always
````

So here do 

````shell script
oc run docker-doc-dev --restart=Never --image registry.hub.docker.com/scoulomb/docker-doctor:dev
oc exec -it docker-doc-dev -- nslookup google.fr
````

We use the form ["without entrypoint override"](#and-without-entrypoint-override-k-run) where I replace /bin/sh by instruction.
To make some space on your machine

````shell script
docker system prune
````

## I have a connectivity issue, where to start?

Usually connexion issue can be due to:
- a firewall rule (roule is source ip, destination ip and **port**),
- a Kubernetes network policy .
- Or hides network issue ([overalapping subnet](https://live.paloaltonetworks.com/t5/general-topics/overlapping-subnets-in-virtual-router-and-nat/td-p/199902)). 

## Link other projects

- In a previous doc, we were listing the same option as in this doc for various way to run a container and the need of a shell for environment var (in run or exec)
https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/4-Run-instructions-into-a-container.md
I consider this doc as a complement of the old doc.
But with the highlight of  
    - here where we had seen that Dockerfile cmd/entrypoint exec form does not process shell (`;` or variable substitution).
https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md#v1-with-problem
    - And what happens with cli override and env var (equivalent to exec)
    https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md#override-entrypoint-and-command
    - we find an issue in old doc and fixed it: https://github.com/scoulomb/myk8s/pull/1
    
    
<!-- this perso project is leveraged in sre-setup pr#27 -->