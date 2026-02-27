FROM rockylinux:9

# Install SSH server and python3 (required for Ansible)
RUN dnf install -y openssh-server python3 shadow-utils sudo && \
    dnf clean all

# Set root password to 'root' for initial ssh-copy-id from master
RUN echo "root:root" | chpasswd

# Generate host keys
RUN ssh-keygen -A

# Allow root login via SSH configuration
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
