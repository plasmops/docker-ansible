FROM python:3.5-alpine3.8

ARG version
ARG version_pin
LABEL com.plasmops.ansible.vendor=PlasmOps \
      com.plasmops.ansible.vendor.version=${version}

# Docker env variables
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 18.09.0
ENV DOCKER_SHASUM 08795696e852328d66753963249f4396af2295a7fe2847b839f7102e25e47cb9
ENV FIXUID_CHECKSUM=e901f3b21e62ebed92172df969bfc6cbfdfa8f53afb060f20f25e77dcbc20ff5

# List of plugins to enable in ZSH and theme
ENV ZSH_PLUGINS="git"
ENV ZSH_THEME=cloud

RUN \
# install essential packages
  apk --no-cache --update add curl bash zsh coreutils sudo openssl openssh-client iptables rsync \
      sed jq fping make git  && \
# install docker-ce binary
  if ! curl -#SL -o docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz"; then \
    echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for x86_64"; \
    exit 1; \
  fi; \
  tar -xzf docker.tgz \
    --strip-components 1 \
    -C /usr/local/bin && \
  echo "${DOCKER_SHASUM}  docker.tgz" | sha256sum -c && rm docker.tgz
## We don't install custom modprobe, since haven't run into issues yet (see the link bellow)
#  https://github.com/docker-library/docker/blob/master/18.06/modprobe.sh
#

RUN \
# run-deps
    apk --no-cache --update add --virtual .run-deps \
        python3-dev libffi-dev openssl-dev build-base && \
# install ansible
    pip install "ansible${version_pin}" boto3 && \
# installing handy tools
    pip install --upgrade pywinrm && \
# clean up
    apk del .run-deps && \
    rm -rf /root/* /root/.* &>/dev/null || /bin/true && \
# adding hosts for convenience...
    mkdir -p /etc/ansible && \
    echo 'localhost' > /etc/ansible/hosts && \
# install fixuid and create an unprivileged user (sudo enabled)
    USER=fixuid && GROUP=fixuid && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    printf "${FIXUID_CHECKSUM}  /usr/local/bin/fixuid" | sha256sum -c && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: ${USER}\ngroup: ${GROUP}\n" > /etc/fixuid/config.yml && \
    adduser -Ds /bin/zsh ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} && \
    chmod 440 /etc/sudoers.d/${USER} && \
# init oh-my-zsh and start it to populate ~/.zshrc
    sudo -H -u ${USER} sh -c "\
        curl -#SL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | bash -s && \
        zsh -c /bin/true \
      " && \
# move current user home into a "skeleton" directory
    mv /home/${USER} /home/_home-skeleton_ && mkdir /home/${USER} && chown ${USER}:${GROUP} /home/${USER}

ADD ./entrypoint.sh /
ENTRYPOINT ["/usr/local/bin/fixuid", "-q", "/entrypoint.sh"]
