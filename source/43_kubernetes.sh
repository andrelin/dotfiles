# Kubernetes helper functions.
[[ ! "$(command -v kubectl)" ]] && return 0
# Tab completions handled by oh-my-zsh kubectl plugin.

# Delete pods matching a pattern in a namespace.
#   kdel my-namespace my-app
function kdel() {
    kubectl -n $1 get pods | grep $2 | cut -f 1 -d ' ' | xargs -n1 kubectl -n $1 delete pod
}

# Delete resources matching a pattern.
#   kdelg deployment my-app
function kdelg() {
    kubectl get $1 | grep $2 | cut -f 1 -d " " | xargs -n1 kubectl delete $1
}

# Force-delete resources matching a pattern.
#   kdelgf deployment my-app
function kdelgf() {
    kubectl get $1 | grep $2 | cut -f 1 -d " " | xargs -n1 kubectl delete $1 --grace-period 0 --force
}

# Delete all resources of a type.
#   kdelall deployment
function kdelall() {
    kubectl get $1 | cut -f 1 -d " " | xargs -n1 kubectl delete $1
}

# Force-delete all resources of a type.
#   kdelallf deployment
function kdelallf() {
    kubectl get $1 | cut -f 1 -d " " | xargs -n1 kubectl delete $1 --grace-period 0 --force
}

# Delete all pods matching a pattern.
#   kdelpg my-app
function kdelpg() {
    kubectl get pod | grep $1 | cut -f 1 -d " " | xargs -n1 kubectl delete pod
}

# Force-delete all pods matching a pattern — for pods stuck in Terminating.
#   kdelpgf my-app
function kdelpgf() {
    kubectl get pod | grep $1 | cut -f 1 -d " " | xargs -n1 kubectl delete pod --grace-period 0 --force
}

# Delete all pods.
function kdelpall() {
    kubectl get pod | cut -f 1 -d " " | xargs -n1 kubectl delete pod
}

# Force-delete all pods.
function kdelpallf() {
    kubectl get pod | cut -f 1 -d " " | xargs -n1 kubectl delete pod --grace-period 0 --force
}

# Delete all PVCs.
function kdelallpvc() {
    kubectl get pvc | cut -f 1 -d " " | xargs -n1 kubectl delete pvc
}
