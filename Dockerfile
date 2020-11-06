FROM ubuntu:20.10
RUN apt-get update
RUN apt install traceroute netcat curl dnsutils -y