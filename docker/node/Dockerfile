FROM rockylinux:9

# Install SSH server and python3 (required for Ansible)
RUN dnf install -y openssh-server python3 shadow-utils sudo && \
    dnf clean all

# Generate host keys
RUN ssh-keygen -A

# Allow root login via SSH configuration using keys only
RUN echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
