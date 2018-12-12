[![Go to Docker Hub](https://img.shields.io/badge/Docker%20Hub-%E2%86%92-blue.svg)](https://hub.docker.com/r/plasmops/ansible/) [![](https://images.microbadger.com/badges/version/plasmops/ansible.svg)](https://microbadger.com/images/plasmops/ansible/) [![](https://images.microbadger.com/badges/image/plasmops/ansible.svg)](https://microbadger.com/images/plasmops/ansible/)

# Ansible alpine based container image

This container image wraps ansible on alpine, zsh, oh-my-zsh and bundles useful tools and CLI utilities. It can be used in two modes non-interactive and interactive.

## Non-Interective mode

In this case you can use the container image directly from docker hub, you will start a privileged container. This is useful for one-off commands, for example:

```bash
docker run -it --rm -v $(pwd):/code -w /code plasmops/ansible ansible-playbook myplay.yml
```

## Interactive mode

Used to provide you with and Ansible development sandbox. With everything ready-to-go. It's recommended that first you create a dedicated home volume to be able safely upgrade/reinstall container.

### Creating the toolbox container

```bash
# create volume first
docker volume create example-ansible-home

# initiate a container
docker run --name example-ansible \
   -u $(id -u):$(id -g) \
   -v example-ansible-home:/home/fixuid \
   -v $(pwd):/code -w /code plasmops/ansible
```

### Using the toolbox container

First we need to initiate a container, you need to change directory of your ansible project (here example project).

```bash
# change to a project directory
cd /path/to/example/project

# starting and attaching to an existing project container
docker start example-ansible && docker attach example-ansible

# exec-ing into the sanbox container
docker exec -ti --env COLUMNS=`tput cols` --env LINES=`tput lines` example-ansible zsh
```

Note that passing the given environment settings fixes the terminal size and colors inside the container, it's advised that you create a special shell profile alias for this like:

```
alias deti="docker exec -ti --env COLUMNS=`tput cols` --env LINES=`tput lines`"
```

### User environment, zsh theme and plugins

It's also possible to configure zsh **on-build** refer to the [section](#building-sandbox-container-image) and supply the following arguments as bellow:

```text
  --build-arg ZSH_PLUGINS="git pyenv" \
  --build-arg ZSH_THEME="cloud" \
```

By default `cloud` theme and `git` plugin are used by providing the above options you can change this behavior.

## License and Authors

Author:: Denis Baryshev (<dennybaa@gmail.com>)
