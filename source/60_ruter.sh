# Shortcuts for changing environment in Ruter
function eks-prod() {
        export AWS_DEFAULT_PROFILE=ruter_prod_eks-gp
        export KUBECONFIG=~/.kubeconfig/ruter_config-prod_eks-gp
}

function eks-devops() {
        export AWS_DEFAULT_PROFILE=ruter_devops
        export KUBECONFIG=~/.kubeconfig/ruter_config-devops
}

function eks-test() {
        export AWS_DEFAULT_PROFILE=ruter_test
        export KUBECONFIG=~/.kubeconfig/ruter_config-test
}

eks-devops