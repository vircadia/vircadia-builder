FROM amazonlinux


RUN yum update -y
#RUN apt install -y libfindbin-libs-perl sudo

COPY files /files
RUN find /files/
RUN /files/install_amazon_linux_deps.sh
RUN /files/vircadia-builder --auto

