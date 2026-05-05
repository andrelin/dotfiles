<!-- DOCTOC SKIP -->

# Local Dev Infrastructure

Helpers for the things that run alongside your code locally — Docker, Kubernetes, Kafka, Postgres.

## Tip 22.1: Docker Cleanup

Reclaim disk and clear out stuck state.

```sh
docker-stop-all          # stop every running container
docker-clean-exited      # remove all exited containers
docker-clean-images      # remove dangling images
docker-clean-all         # nuclear: stop all, prune containers/images/volumes
docker-ip <name>         # IP of a named container
docker-ip-latest         # IP of the most recently started container
```

From `source/21_docker.sh`. The `-clean-` family is composable; reach for `-clean-all` only when you really mean it.

## Tip 22.2: Kubernetes Pod Surgery

Bulk-delete pods/resources by pattern. Operates against the current `kubectl` context, so know your context before running.

```sh
kdel <namespace> <name-substring>         # delete pods matching substring in <namespace>
kdelpg <name-substring>                   # delete pods matching substring in current namespace
kdelg <kind> <name-substring>             # delete resources of <kind> matching substring
kdelgf <kind> <name-substring>            # same, but with --force --grace-period=0
kdelall <kind>                            # delete all resources of <kind> in current namespace
kdelallpvc                                # delete all PVCs in current namespace
```

From `source/43_kubernetes.sh`. Cross-link: see `40_kubernetes_cli.md` for the upstream `kubectl` / `kubectx` / `k9s` tools.

## Tip 22.3: Kafka Topic Helpers

Higher-level wrappers around `kafka-topics` and friends. Configured via `KAFKA_BOOTSTRAP` and `SCHEMA_REGISTRY` env vars (default to `localhost`); set them in your shell or a `.envrc` per project.

```sh
kafka-grep <pattern>                      # list topics matching a pattern
kafka-delete-matching <pattern>           # delete topics matching a pattern (be careful)
kafka-cg-describe <consumer-group>        # describe a consumer group's offsets
kafka-consume-avro <topic>                # consume Avro-encoded messages with schema registry
```

From `source/42_kafka.sh`. Cross-link: see `41_kafka_cli.md` for the underlying CLI.

## Tip 22.4: Throwaway Postgres

Spin up a Docker-backed local Postgres in seconds.

```sh
mkpg <name>     # docker run a postgres named <name>; user=db=password=<name>
repg            # stop+remove+recreate a container named "postgres"
```

`mkpg foo` gives you a Postgres running on `localhost:5432` with credentials `foo/foo` and a `foo` database — convenient for quick local testing. `repg` resets the default-named one. From `source/44_postgres.sh`.
