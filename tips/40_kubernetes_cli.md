<!-- DOCTOC SKIP -->

# Kubernetes CLI

Upstream Kubernetes tooling. **All optional installs** — this machine doesn't have a cluster wired up by default. Each tip leads with the install command. Repo helpers like `kdel*` live in `22_dev_infra.md` (Tip 22.2).

## Tip 40.1: kubectl

```sh
brew install kubernetes-cli

kubectl get pods                              # list pods in current namespace
kubectl logs <pod>                            # show pod logs (-f to follow)
kubectl exec -it <pod> -- bash                # shell into a pod
kubectl get <kind> -A                         # all resources of <kind> across namespaces
```

Docs: <https://kubernetes.io/docs/reference/kubectl/>

## Tip 40.2: kubectx / kubens

Interactive cluster and namespace switching.

```sh
brew install kubectx

kubectx                  # interactive picker for cluster context
kubens                   # interactive picker for namespace
kubectx <name>           # switch directly
kubens <name>            # switch directly
kubectx -                # toggle to previous context
```

Docs: <https://github.com/ahmetb/kubectx>

## Tip 40.3: kube-ps1

Adds the current `<cluster>:<namespace>` to your shell prompt so you always know what `kubectl` will hit.

```sh
brew install kube-ps1
```

Configure with `KUBE_PS1_*` env vars; toggle on/off with `kubeon` / `kubeoff` after sourcing the plugin.

Docs: <https://github.com/jonmosco/kube-ps1>

## Tip 40.4: k9s

Terminal UI for Kubernetes. Massively faster than chained `kubectl` for live debugging — see pods, logs, events, descriptions, all with single-key navigation.

```sh
brew install k9s

k9s                  # launch
:pods                # jump to pods view
:svc                 # services
:ns                  # namespaces (and switch into one)
?                    # help
:q                   # quit
```

Docs: <https://k9scli.io/>
