[![Go to Docker Hub](https://img.shields.io/badge/Docker%20Hub-%E2%86%92-blue.svg)](https://hub.docker.com/r/plasmops/ansible/) [![](https://images.microbadger.com/badges/version/stackfeed/alpine-python3.svg)](https://microbadger.com/images//plasmops/ansible/) [![](https://images.microbadger.com/badges/image/stackfeed/alpine-python3.svg)](https://microbadger.com/images//plasmops/ansible/)

# Ansible alpine based container image

This container image wraps ansible on alpine, zsh, oh-my-zsh and bundles useful tools and CLI utilities. It can be used in two modes non-interactive and interactive.

## Non-Interective mode

In this case you can use the container image directly from docker hub, you will start a privileged container. This is useful for one-off commands, for example:

```bash
docker run -it --rm -v $(pwd):/code plasmops/ansible ansible-playbook myplay.yml
```

## Interactive mode

Used to provide you ansible sandbox you can develop your playbooks in your favorite editor while applying configurations in a container sanbox. This mode requires an additional step to build a child container image based on `plasmops/ansible`, a newly built container image contains ***an underprivileged user*** matching your host system for ease of use and development.

### Building sandbox container image

```bash
_USER=$(id -un)
_UID=$(id -u)
_GID=$(id -g)

mkdir -p /tmp/plasmops-ansible-sandbox && cd /tmp/plasmops-ansible-sandbox
echo "FROM plasmops/ansible" > Dockerfile

docker build --no-cache -t ansible-sandbox \
             --build-arg _USER=${_USER} \
             --build-arg _UID=${_UID} \
             --build-arg _GID=${_GID} .

cd - && rm -rf /tmp//plasmops-ansible-sandbox
```

### Using an underprivileged sandbox

First we need to initiate a container, you need to change directory of your ansible project (here example project).

```bash
# change to a project directory
cd /path/to/example/project

# initiate the sanbox container
docker run --name example-ansible $(pwd):/code zsh

# starting and attaching to an existing project container
docker start example-ansible && docker attach example-ansible

# execing into the sanbox container
docker exec -ti --env COLUMNS=`tput cols` --env LINES=`tput lines` example-ansible zsh
```

Note that passing the given environment settings fixes the terminal size and colors inside the container, it's advised that you create a special shell profile alias for this like:

```
alias deti="docker exec -ti --env COLUMNS=`tput cols` --env LINES=`tput lines`"
```

#### User environment and zsh theme and plugins

It's also possible to configure zsh **on-build** refer to the [section](#building-sandbox-container-image) and supply the following arguments as bellow:

```text
  --build-arg ZSH_PLUGINS="git pyenv" \
  --build-arg ZSH_THEME="cloud" \
```

By default `cloud` theme and `git` plugin are used by providing the above options you can change this behavior.

While working as unprivileged user your home directory will be initialized since the beginning, so you are free to change your `~/.zshrc`  and any other directories in your home, mind that **once you delete container all the data** from your home directory **will be lost**!

**Also there's a handy home directory auto-population ability** is available with the container, provide a space-separated list of directories inside your project directory such as: *`.aws`, `.ssh`* etc as `--env POPULATE=".aws .ssh"` and if they exist they will be auto-symlinked into your container home directory. By default `POPULATE=".ssh"`.

## License and Authors

Author:: Denis Baryshev (<dennybaa@gmail.com>)
