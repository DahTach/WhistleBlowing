FROM debian:12-slim

RUN apt-get update -q && \
    apt-get install -y wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/DahTach/WhistleBlowing/blob/a4420d4ef4dd197488d672bb949507d50d82e69e/install.sh
RUN chmod +x install.sh
RUN ./install.sh -y -n

VOLUME [ "/var/globaleaks/" ]

EXPOSE 8080
EXPOSE 4443

CMD ["/usr/bin/python3", "/usr/bin/globaleaks", "--working-path=/var/globaleaks/", "-n"]
