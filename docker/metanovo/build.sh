#/usr/bin/env bash

# Change build context to the root of the directory

cd ../..

docker build --build-arg ftp_proxy=$ftp_proxy --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy -f docker/metanovo/Dockerfile -t cbio/metanovo .
