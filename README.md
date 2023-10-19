# WhistleBlowing

Globaleaks deployment test

## Build the image with

`docker build -t globalwhistle .`

## Run the image after building with

`docker run --rm -it -p '80:8080' -p '443:8443' globalwhistle`
