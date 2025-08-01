#!/bin/bash

# Отключаем BuildKit, чтобы не использовать отсутствующий плагин buildx
export DOCKER_BUILDKIT=0

# Файл, в котором будет храниться ID кластера
ID_FILE="./.cluster_id"

# Проверяем, существует ли файл с ID
if [ -f "$ID_FILE" ]; then
  # Если файл есть, читаем ID из него
  echo "Cluster ID file found. Using existing ID."
  CLUSTER_ID=$(cat $ID_FILE)
else
  # Если файла нет, генерируем новый ID и сохраняем его
  echo "Cluster ID file not found. Generating a new ID..."
  CLUSTER_ID=$(docker run --rm confluentinc/cp-kafka:7.3.0 kafka-storage random-uuid)
  echo $CLUSTER_ID > $ID_FILE
  echo "New Cluster ID ($CLUSTER_ID) saved to $ID_FILE"
fi

# Экспортируем переменную, чтобы docker-compose мог ее использовать
export CLUSTER_ID

# Запускаем docker-compose
echo "Starting Docker Compose services..."
docker compose down -v
docker compose up -d --build

echo "Services are starting up."