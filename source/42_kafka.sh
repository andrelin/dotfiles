# Kafka helper functions.
# Requires: brew install kafka (for kafka-topics, kafka-consumer-groups)
# kafka-consume-avro additionally requires kafka-avro-console-consumer from
# Confluent Platform: https://docs.confluent.io/platform/current/installation/
#
# Set KAFKA_BOOTSTRAP and SCHEMA_REGISTRY env vars to target a specific
# cluster (defaults to localhost). Works well with direnv per-project.
[[ ! "$(command -v kafka-topics)" ]] && return 0

# List topics matching a pattern.
#   kafka-grep my-app
kafka-grep() {
    kafka-topics --bootstrap-server "${KAFKA_BOOTSTRAP:-localhost:9092}" --list \
    | grep "$1"
}

# Delete topics matching a pattern.
#   kafka-delete-matching my-app
kafka-delete-matching() {
    kafka-topics --bootstrap-server "${KAFKA_BOOTSTRAP:-localhost:9092}" --list \
    | grep "$1" \
    | xargs -n1 kafka-topics --bootstrap-server "${KAFKA_BOOTSTRAP:-localhost:9092}" --delete --topic
}

# Describe a consumer group.
#   kafka-cg-describe my-consumer-group
kafka-cg-describe() {
    kafka-consumer-groups --bootstrap-server "${KAFKA_BOOTSTRAP:-localhost:9092}" --describe --group "$1"
}

# Consume from a topic with avro deserialization.
#   kafka-consume-avro my-topic
kafka-consume-avro() {
    kafka-avro-console-consumer \
    --bootstrap-server "${KAFKA_BOOTSTRAP:-localhost:9092}" \
    --topic "$1" \
    --property print.key=true \
    --key-deserializer=org.apache.kafka.common.serialization.StringDeserializer \
    --property schema.registry.url="${SCHEMA_REGISTRY:-http://localhost:8081}" \
    "${@:2}"
}
