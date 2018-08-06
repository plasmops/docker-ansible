FROM stackfeed/alpine-python3:latest

LABEL vendor=PlasmOPs \
      version_tags="[\"2.6\"]"

ENV POPULATE=".ssh"

# List of plugins to enable in ZSH and theme
ONBUILD ARG ZSH_PLUGINS="git"
ONBUILD ARG ZSH_THEME=cloud

# Host user *IDs
ONBUILD ARG _USER=user
ONBUILD ARG _UID=1000
ONBUILD ARG _GID=1000

RUN apk --no-cache --update add \
        zsh sed vim sudo jq fping make git openssl openssh-client iptables rsync && \
# run-deps
    apk --no-cache --update add --virtual .run-deps \
        python3-dev libffi-dev openssl-dev build-base && \
# install ansible
    pip install 'ansible<=2.7' && \
# installing handy tools
    pip install --upgrade pywinrm && \
# clean up
    apk del .run-deps && \
    rm -rf /root/* /root/.* &>/dev/null || /bin/true && \
# adding hosts for convenience...
    mkdir -p /etc/ansible && \
    echo 'localhost' > /etc/ansible/hosts

# Configure unprivileged user (remember NOT TO USE adduser from busybox!)
ONBUILD RUN \
# create user & group if those don't exist
    ( getent group ${_GID} &>/dev/null || groupadd -g ${_GID} ${_USER} ) && \
    ( id ${_UID} &>/dev/null || useradd -s /bin/zsh -md /home/${_USER} -u ${_UID} -g ${_GID} ${_USER} ) && \
    echo "#${_UID} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${_USER} && \
    chmod 440 /etc/sudoers.d/${_USER}

# Copy data
ADD  ./entrypoint.sh /

VOLUME ["/code"]
WORKDIR "/code"
ENTRYPOINT ["/entrypoint.sh"]
