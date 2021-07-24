FROM fedora:33


RUN dnf update -y
RUN dnf install -y perl
COPY files /files
RUN /files/vircadia-builder --auto




