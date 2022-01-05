# Not RHEL-tested. Abort if RHEL
is_rhel && return 1

# Remove all docker containers and images
function dockerclean () { (
	docker rm -f $(docker ps -a -q) || true) && (docker rmi -f $(docker images -q) || true) && (docker volume rm $(docker volume ls |awk '{print $2}') || true) ;
}

# Stop all docker containers
function dockerstopall () { 
	(docker rm -f $(docker ps -a -q)) 
} 

function docker-ip () {
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' $@
}

function docker-ip-latest () {
    docker-ip $(docker ps -l -q)
}

function docker-clean-exited () {
    docker rm $(docker ps -q -f status=exited)
}

function docker-clean-images () {
    docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
}

function docker-stop-all () {
    docker stop $(docker ps -q -f status=running)
}
