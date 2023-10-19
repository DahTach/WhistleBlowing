FROM debian:12-slim

RUN apt-get update -q && \
    apt-get install -y wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://raw.githubusercontent.com/DahTach/WhistleBlowing/main/install.sh
RUN chmod +x install.sh
RUN ./install.sh -y -n

VOLUME [ "/var/globaleaks/" ]

EXPOSE 8080
EXPOSE 4443

CMD ["/usr/bin/python3", "/usr/bin/globaleaks", "--working-path=/var/globaleaks/", "-n"]
