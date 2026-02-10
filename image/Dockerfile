FROM ubuntu:24.04

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        git \
        ca-certificates \
        curl \
        tmux \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create git user with git-shell (restricted access)
RUN useradd -m -d /home/git -s /usr/bin/git-shell git && \
    mkdir -p /home/git/.ssh && \
    chmod 700 /home/git/.ssh && \
    touch /home/git/.ssh/authorized_keys && \
    chmod 600 /home/git/.ssh/authorized_keys && \
    chown -R git:git /home/git

# Configure sudo for root to run commands as git user
RUN echo "root ALL=(git) NOPASSWD: ALL" > /etc/sudoers.d/git-user && \
    chmod 0440 /etc/sudoers.d/git-user

# Create git-shell-commands directory (required by git-shell)
RUN mkdir -p /home/git/git-shell-commands && \
    chown git:git /home/git/git-shell-commands

# Create repository directory
RUN mkdir -p /srv/git && \
    chown git:git /srv/git

# Configure SSH server
RUN mkdir -p /run/sshd && \
    mkdir -p /etc/ssh/ssh_host_keys

# Copy SSH configuration
COPY sshd_config /etc/ssh/sshd_config

# Copy helper scripts
COPY init-repo.sh /usr/local/bin/init-repo.sh
RUN chmod +x /usr/local/bin/init-repo.sh

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Declare volumes
VOLUME ["/srv/git", "/home/git/.ssh", "/etc/ssh/ssh_host_keys"]

# Expose SSH port
EXPOSE 22

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
