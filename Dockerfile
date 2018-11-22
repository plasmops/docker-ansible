FROM stackfeed/alpine-python3:latest

LABEL vendor=PlasmOps \
      version_tags="[\"2.6\"]"

ENV POPULATE=".ssh .ansible.cfg"

# Docker env variables
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 18.09.0
ENV DOCKER_SHASUM 08795696e852328d66753963249f4396af2295a7fe2847b839f7102e25e47cb9

# List of plugins to enable in ZSH and theme
ONBUILD ARG ZSH_PLUGINS="git"
ONBUILD ARG ZSH_THEME=cloud

# Host user *IDs
ONBUILD ARG _USER=user
ONBUILD ARG _UID=1000
ONBUILD ARG _GID=1000

RUN apk --no-cache --update add \
        zsh sed coreutils vim sudo jq fping make git openssl openssh-client iptables rsync && \
# run-deps
    apk --no-cache --update add --virtual .run-deps \
        python3-dev libffi-dev openssl-dev build-base && \
# install ansible
    pip install 'ansible<=2.7' boto3 && \
# installing handy tools
    pip install --upgrade pywinrm && \
# clean up
    apk del .run-deps && \
    rm -rf /root/* /root/.* &>/dev/null || /bin/true && \
# adding hosts for convenience...
    mkdir -p /etc/ansible && \
    echo 'localhost' > /etc/ansible/hosts

# Install AWS CLI (latest) and utilities required
RUN pip install awscli && apk add --no-cache groff less mailcap

## Install docker-ce
#
RUN \
  if ! curl -#fL -o docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz"; then \
    echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for x86_64"; \
    exit 1; \
  fi; \
  \
  tar -xzf docker.tgz \
    --strip-components 1 \
    -C /usr/local/bin && \
  \
  echo "${DOCKER_SHASUM}  docker.tgz" | sha256sum -c && rm docker.tgz
## We don't install custom modprobe, since haven't run into issues yet (see the link bellow)
#  https://github.com/docker-library/docker/blob/master/18.06/modprobe.sh
#

# Copy data
ADD  ./entrypoint.sh /

# Configure unprivileged user (remember NOT TO USE adduser from busybox!)
ONBUILD RUN \
# create user & group if those don't exist
    ( getent group ${_GID} &>/dev/null || groupadd -g ${_GID} ${_USER} ) && \
    ( id ${_UID} &>/dev/null || useradd -s /bin/zsh -md /home/${_USER} -u ${_UID} -g ${_GID} ${_USER} ) && \
    echo "#${_UID} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${_USER} && \
    chmod 440 /etc/sudoers.d/${_USER}

# Set unprivileged user
ONBUILD USER $_UID:$_GID
ONBUILD RUN \
# install oh-my-zsh and enable given plugins and theme (use bash to install)
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
    awk '/^plugins=\(/,/\)/ { if ( $0 ~ /^plugins=\(/ ) print "plugins=('"${ZSH_PLUGINS}"')"; next } 1' ~/.zshrc > /tmp/.zshrc && \
    mv /tmp/.zshrc ~/.zshrc && sed -i 's/\(ZSH_THEME\)=".*"/\1="'${ZSH_THEME}'"/' ~/.zshrc

VOLUME ["/code"]
WORKDIR "/code"
ENTRYPOINT ["/entrypoint.sh"]
