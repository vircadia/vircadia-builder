FROM ubuntu:18.04


RUN apt update
RUN apt install -y libfindbin-libs-perl sudo

COPY files /files
RUN find /files/
RUN /files/vircadia-builder --auto




