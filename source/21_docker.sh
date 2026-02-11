# Docker helper functions.
[[ ! "$(command -v docker)" ]] && return 0

# shellcheck disable=SC2046 # Word splitting is intentional — passes multiple container IDs as separate args
function docker-stop-all() {
    docker stop $(docker ps -q -f status=running)
}

# shellcheck disable=SC2046 # Word splitting is intentional — passes multiple container IDs as separate args
function docker-clean-exited() {
    docker rm $(docker ps -q -f status=exited)
}

# shellcheck disable=SC2046 # Word splitting is intentional — passes multiple image IDs as separate args
function docker-clean-images() {
    docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
}

# shellcheck disable=SC2046 # Word splitting is intentional — passes multiple container/image IDs as separate args
function docker-clean-all() {
    (docker rm -f $(docker ps -a -q) || true) \
    && (docker rmi -f $(docker images -q) || true) \
    && (docker volume rm $(docker volume ls --format '{{.Name}}') || true)
}

function docker-ip() {
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
}

# shellcheck disable=SC2046 # Word splitting is intentional — passes container ID as arg
function docker-ip-latest() {
    docker-ip $(docker ps -l -q)
}
