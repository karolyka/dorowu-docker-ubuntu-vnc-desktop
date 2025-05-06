FROM ubuntu:25.04

# Environment Configuration
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    container=docker \
    SYSTEMD_PAGERSECURE=yes \
    PYTHONDONTWRITEBYTECODE=1

# ------------------------------------------------------------------------------

# Install packages and configure system
RUN apt-get update -q && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      sudo \
      systemd \
      cron \
      dbus \
      locales \
      openssh-server \
      rsyslog \
      iproute2 \
      iputils-ping \
      mc \
      net-tools \
      nginx \
      tzdata \
      supervisor \
      lxde \
      x11vnc \
      dbus-x11 \
      x11-utils \
      xvfb \
      wget \
      curl && \
    # Configure locale
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    # Create essential man directories before cleanup
    mkdir -p /usr/share/man/man1

# ------------------------------------------------------------------------------

# Systemd Configuration
RUN systemctl set-default multi-user.target && \
    # Remove problematic services instead of masking
    rm -f /lib/systemd/system/getty.target && \
    rm -f /lib/systemd/system/systemd-udevd.service && \
    rm -f /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup-dev*
#    rm -f /lib/systemd/system/sys-kernel-config.mount && \
#    rm -f /lib/systemd/system/sys-kernel-debug.mount && \
#    rm -f /lib/systemd/system/sys-kernel-tracing.mount && \
#    rm -f /lib/systemd/system/kmod-static-nodes.service && \
#    rm -f /lib/systemd/system/systemd-modules-load.service

# ------------------------------------------------------------------------------

# Security and Access Configuration
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf && \
    echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    passwd -d root && \
    ssh-keygen -A

# ------------------------------------------------------------------------------

RUN wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | \
    tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

RUN echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | \
    tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null

RUN echo '\n\
    Package: *\n\
    Pin: origin packages.mozilla.org\n\
    Pin-Priority: 1000\n\
    \n\
    Package: firefox*\n\
    Pin: release o=Ubuntu\n\
    Pin-Priority: -1' | \
    tee /etc/apt/preferences.d/mozilla

RUN apt update -q && apt upgrade -y

# ------------------------------------------------------------------------------

RUN apt-get clean && \
    rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/* \
        /var/log/*log \
        /var/log/apt/* \
        /var/log/dpkg.log \
        /usr/share/doc/*

# ------------------------------------------------------------------------------

ADD image /

RUN sed -i 's|exit 101|exit 0|g' /usr/sbin/policy-rc.d

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
