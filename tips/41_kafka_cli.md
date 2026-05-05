<!-- DOCTOC SKIP -->

# Kafka CLI

Apache Kafka command-line tools. **Optional install** (`brew install kafka`). Repo's higher-level helpers (`kafka-grep`, `kafka-delete-matching`, etc.) live in `22_dev_infra.md` (Tip 22.3).

## Tip 41.1: Topics

Manage topics with `kafka-topics`. Prefix every command with `--bootstrap-server <broker>:9092`.

```sh
kafka-topics --bootstrap-server localhost:9092 --list
kafka-topics --bootstrap-server localhost:9092 --create --topic my-topic --partitions 3 --replication-factor 1
kafka-topics --bootstrap-server localhost:9092 --describe --topic my-topic
kafka-topics --bootstrap-server localhost:9092 --delete --topic my-topic
```

Docs: <https://kafka.apache.org/documentation/>

## Tip 41.2: Console Consumer

Read messages from a topic.

```sh
kafka-console-consumer --bootstrap-server localhost:9092 --topic my-topic --from-beginning
kafka-console-consumer --bootstrap-server localhost:9092 --topic my-topic --max-messages 10
```

`--from-beginning` reads everything; without it you only see messages produced after you start consuming.

## Tip 41.3: Console Producer

Write messages to a topic — type lines, hit Enter, each line is a message.

```sh
kafka-console-producer --bootstrap-server localhost:9092 --topic my-topic
> hello
> another message
^D                                # finish
```

Combine with the consumer in another shell to test end-to-end.
