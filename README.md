# Docker doctor

## Objective

Tool to diagnose network issue when we can not run a container as root in a given Kubernetes cluster.
This requires the permission to create a pod in a namespace.

We baked our own image, because `busybox` (among others) does not accept `traceroute` when not allowed to run a container as root.
This is the case  in many situation (and is configured with psp/scc by cluster admin).

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


Note some cluster requires docker hub full path.
See more [info](https://stackoverflow.com/questions/34198392/docker-official-registry-docker-hub-url).

### Docker

````shell script
# rmi in case update and had former version
sudo docker rmi scoulomb/docker-doctor:dev
sudo docker rmi registry.hub.docker.com/scoulomb/docker-doctor:dev
# This will also pull
sudo docker run -it --entrypoint /bin/sh scoulomb/docker-doctor:dev
sudo docker run -it --entrypoint /bin/sh registry.hub.docker.com/scoulomb/docker-doctor:dev # first it will go through artifactory and see all layer there
````

Output

````shell script
sylvain@sylvain-hp:~/docker-doctor$ sudo docker run -it --entrypoint /bin/sh registry.hub.docker.com/scoulomb/docker-doctor:dev
Unable to find image 'registry.hub.docker.com/scoulomb/docker-doctor:dev' locally
dev: Pulling from scoulomb/docker-doctor
Digest: sha256:e25bfd7925c517d21e2ffaaab1b483e42943f8b769f52c3b0a39a4b5361523d0
Status: Downloaded newer image for registry.hub.docker.com/scoulomb/docker-doctor:dev
````

And without entrypoint override (as we in kubernetes reather than checking logs)

````shell script
sudo docker run -d --name doc1 registry.hub.docker.com/scoulomb/docker-doctor:dev
 sudo docker exec -it doc1 /bin/sh # and 
````

### Kubernetes

This is useful to connectivty between a docker running inside a pod in your cluster to outside.
It a kubeclt conext config which will send you to your cluster (it depends on your machine/user).
On minikube it is setup for you ([oc client, see below](#i-am-using-openshift-cli) does the same).

See here for `kubectl run` deep dive: https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/0-kubectl-run-explained.md

Note": use [imagePullPolicy](https://kubernetes.io/docs/concepts/containers/images/) to always if updated a version with same tag, otherwise if not present will apply.
(same issue when did ``docker rmi``).

````shell script
sudo kubectl run docker-doc-dev --image registry.hub.docker.com/scoulomb/docker-doctor:dev --restart=OnFailure --image-pull-policy=Always
sudo kubectl exec -it  docker-doc-dev /bin/sh # and -- will prevent from working unlike kubectl
````

### Features

````shell script
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


Note on traceroute portocol 

````shell script
On Unix-like operating systems, traceroute sends, by default, a sequence of User Datagram Protocol (UDP) packets, with destination port numbers ranging from 33434 to 33534; the implementations of traceroute shipped with Linux,[2] FreeBSD,[3] NetBSD,[4] OpenBSD,[5] DragonFly BSD,[6] and macOS include an option to use ICMP Echo Request packets (-I), or any arbitrary protocol (-P) such as UDP, TCP using TCP SYN packets, or ICMP.[7]

On Windows, tracert sends ICMP Echo Request packets, rather than the UDP packets traceroute sends by default.[8]
````


But we can  force to do a TCP traceroute and specify the port.


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