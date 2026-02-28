FROM rockylinux:9

# Install epel-release, ansible, ssh clients
RUN dnf install -y epel-release yum-utils && \
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    dnf install -y ansible-core openssh-clients python3 python3-pip python3-devel gcc docker-ce-cli && \
    dnf clean all

WORKDIR /playbooks

CMD ["tail", "-f", "/dev/null"]
