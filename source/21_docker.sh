# Docker helper functions.
[[ ! "$(command -v docker)" ]] && return 0

function docker-stop-all() {
    docker stop $(docker ps -q -f status=running)
}

function docker-clean-exited() {
    docker rm $(docker ps -q -f status=exited)
}

function docker-clean-images() {
    docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
}

function docker-clean-all() {
    (docker rm -f $(docker ps -a -q) || true) \
    && (docker rmi -f $(docker images -q) || true) \
    && (docker volume rm $(docker volume ls --format '{{.Name}}') || true)
}

function docker-ip() {
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
}

function docker-ip-latest() {
    docker-ip $(docker ps -l -q)
}
