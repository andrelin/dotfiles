# Not RHEL-tested. Abort if RHEL
is_rhel && return 1

kdel () {
    kubectl -n $1 get pods | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn} $2 | cut -f 1 -d ' ' | xargs -n1 kubectl -n $1 delete pod
}

kdelg() {
    kubectl get $1 | grep $2 | cut -f 1 -d " " | xargs -n1 kubectl delete $1
}

kdelgf() {
    kubectl get $1 | grep $2 | cut -f 1 -d " " | xargs -n1 kubectl delete $1 --grace-period 0 --force
}

kdelall(){
    kubectl get $1 | cut -f 1 -d " " | xargs -n1 kubectl delete $1
}

kdelallf(){
    kubectl get $1 | cut -f 1 -d " " | xargs -n1 kubectl delete $1 --grace-period 0 --force
}

kdelpg() {
    kubectl get pod | grep $1 | cut -f 1 -d " " | xargs -n1 kubectl delete pod
}

kdelpgf() {
    kubectl get pod | grep $1 | cut -f 1 -d " " | xargs -n1 kubectl delete pod --grace-period 0 --force
}

kdelpall(){
    kubectl get pod | cut -f 1 -d " " | xargs -n1 kubectl delete pod
}

kdelpallf(){
    kubectl get pod | cut -f 1 -d " " | xargs -n1 kubectl delete pod --grace-period 0 --force
}

kdelallpvc(){
    kubectl get pvc | cut -f 1 -d " " | xargs -n1 kubectl delete pvc
}

# TODO: Generify bash login commands
kafkatools(){
    kubectl get pods -n rdp-monitoring | grep kafkatools | cut -d" " -f1 | xargs -o -I% -L1 kubectl exec -it %  -n rdp-monitoring -- bash
}

kafkatools-msk(){
    kubectl get pods -n rdp-monitoring | grep kafka-msk-tools | cut -d" " -f1 | xargs -o -I% -L1 kubectl exec -it %  -n rdp-monitoring -- bash
}


# TODO: Generify port fwd commands
def fwd-jenkins() {
    export JENKINS_POD_NAME=$(kubectl get pods --namespace core -l "app.kubernetes.io/component=jenkins-master" -l "app.kubernetes.io/instance=jenkins" -o jsonpath="{.items[0].metadata.name}")
    kubectl --namespace core port-forward $JENKINS_POD_NAME 8081:8080
}

def fwd-chartmuseum() {
    export CHARTMUSEUM_POD_NAME=$(kubectl get pods --namespace core -l "app=chartmuseum" -l "release=chartmuseum" -o jsonpath="{.items[0].metadata.name}")
    kubectl --namespace core port-forward $CHARTMUSEUM_POD_NAME 8080:8080
}