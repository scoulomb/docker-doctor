FROM ubuntu:20.10
RUN apt-get update
RUN apt install traceroute netcat curl dnsutils iputils-ping  openssh-client -y

WORKDIR /data
COPY ./loop.sh /data/loop.sh
RUN chmod u+x /data/loop.sh

ENTRYPOINT ["/data/loop.sh"]