FROM debian:12-slim

RUN apt-get update -q && \
    apt-get install -y wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/DahTach/WhistleBlowing/blob/8025390b5db75cf3c9bb1ea760bd54925e31313a/install.sh
RUN chmod +x install.sh
RUN ./install.sh -y -n

RUN apt-get remove wget

VOLUME [ "/var/globaleaks/" ]

EXPOSE 8080
EXPOSE 4443

CMD ["/usr/bin/python3", "/usr/bin/globaleaks", "--working-path=/var/globaleaks/", "-n"]
