#/usr/bin/env bash

# Change build context to the root of the directory
cd ../..
sudo docker build --build-arg ftp_proxy=$ftp_proxy --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy -f docker/mqproteogenomics/Dockerfile  -t cbio/mqproteogenomics:latest .
