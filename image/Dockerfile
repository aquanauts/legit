FROM ubuntu:24.04

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        git \
        ca-certificates \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create git user with git-shell (restricted access)
RUN useradd -m -d /home/git git && \
    passwd -d git && \
    mkdir -p /home/git/.ssh && \
    chmod 700 /home/git/.ssh && \
    touch /home/git/.ssh/authorized_keys && \
    chmod 600 /home/git/.ssh/authorized_keys

# Create git-shell-commands directory (required by git-shell)
RUN mkdir -p /home/git/git-shell-commands

# Create repository directory
RUN mkdir -p /home/git/repos

# Configure SSH server
RUN mkdir -p /run/sshd && \
    mkdir -p /etc/ssh/ssh_host_keys

# Copy SSH configuration
COPY sshd_config /etc/ssh/sshd_config

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY authorized_keys_command.sh /root/authorized_keys_command.sh
RUN chmod +x /root/authorized_keys_command.sh

COPY git-shell-wrapper /usr/bin/git-shell-wrapper
RUN chmod +x /usr/bin/git-shell-wrapper

COPY hooks /home/git/hooks
RUN chmod +x /home/git/hooks/*

# Ensure git owns all files in home dir
RUN chown -R git:git /home/git

# Declare volumes
VOLUME ["/home/git/.ssh", "/etc/ssh/ssh_host_keys"]

# Expose SSH port
EXPOSE 22

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
