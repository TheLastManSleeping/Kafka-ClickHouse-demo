#!/bin/bash
set -e

# Путь к файлу с ID на постоянном томе.
# /bitnami/kafka - это стандартный путь для данных в этом образе.
ID_FILE="/bitnami/kafka/cluster_id"

# Проверяем, существует ли файл
if [ ! -f "$ID_FILE" ]; then
    echo "Cluster ID file not found. Generating new CLUSTER_ID..."
    # Генерируем ID и сохраняем в файл
    KAFKA_CLUSTER_ID=$(kafka-storage.sh random-uuid)
    echo "$KAFKA_CLUSTER_ID" > "$ID_FILE"
else
    echo "Found existing CLUSTER_ID..."
    # Читаем ID из файла
    KAFKA_CLUSTER_ID=$(cat "$ID_FILE")
fi

# Экспортируем переменную, чтобы Kafka мог ее использовать
export KAFKA_CLUSTER_ID

echo "Starting Kafka with CLUSTER_ID: $KAFKA_CLUSTER_ID"

# Запускаем оригинальный стартовый скрипт Bitnami, который сделает все остальное
exec /opt/bitnami/scripts/kafka/entrypoint.sh /opt/bitnami/scripts/kafka/run.sh