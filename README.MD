# Демонстрационный стенд: Kafka + ClickHouse

Этот проект представляет собой готовый `docker-compose` стенд для демонстрации интеграции Apache Kafka и ClickHouse в режиме реального времени. Включает в себя генератор событий, который отправляет данные в Kafka, и ClickHouse, который автоматически их забирает и раскладывает по разным таблицам в зависимости от топика.

## Архитектура

Процесс обработки данных выглядит следующим образом:

```
[Event Emitter] ---> [Kafka Topics: clicks, views, orders] ---> [ClickHouse]
 (Python)                                                          |
                                                                   +---> [clicks_table]
                                                                   +---> [views_table]
                                                                   +---> [orders_table]
```
## Структура проекта

```
.
├── docker-compose.yml      # Главный файл, описывающий все сервисы
├── kafka-entrypoint.sh     # Скрипт для автоматизированной генерации ID для Kafka
├── clickhouse_init/
│   └──init.sql          # SQL-схема: таблицы и материализованные представления
└── emitter/
    ├── Dockerfile          # Dockerfile для сборки образа генератора событий
    ├── emitter.py          # Python-скрипт, генерирующий и отправляющий события
    └── requirements.txt    # Зависимости для Python-скрипта
```

## Сервисы

  * **`kafka`**: Брокер сообщений, работающий в режиме **KRaft** (без ZooKeeper). Принимает события от продюсера.
  * **`clickhouse-server`**: Аналитическая база данных для хранения и обработки событий в реальном времени.
  * **`event-emitter`**: Python-скрипт, который генерирует три типа событий и отправляет их в соответствующие топики Kafka (`user_clicks`, `page_views`, `orders`).

## Ключевые особенности

  * **Автоматическая инициализация ClickHouse**: Таблицы и материализованные представления-маршрутизаторы создаются автоматически при первом запуске с помощью скрипта-обертки, который ожидает готовности Kafka.
  * **Маршрутизация событий**: Данные из разных топиков Kafka попадают в разные, строго типизированные таблицы в ClickHouse.
  * **Настраиваемый генератор**: Скорость отправки сообщений и параметры продюсера (`acks`, `batch_size` и т.д.) можно легко настраивать через переменные окружения в `docker-compose.yml`.

## Необходимые условия

  * **Docker**
  * **Docker Compose v2** 

## Запуск проекта

1.  Склонируйте репозиторий:
    ```bash
    git clone https://github.com/TheLastManSleeping/kafka-clickhouse-demo.git
    ```
2.  Запустите все сервисы:
    ```bash
    docker compose up -d --build
    ```

## Остановка проекта

  * Для остановки всех сервисов и удаления контейнеров:
    ```bash
    docker compose down
    ```
  * Для **полной очистки** (включая данные ClickHouse и сгенерированный ID Kafka):
    ```bash
    docker compose down -v
    sudo rm -rf ./clickhouse_data ./.cluster_id
    ```

## Полезные команды

### Просмотр статуса сервисов

```bash
docker compose ps
```

### Доступ к ClickHouse

1.  Подключиться к командной строке:
    ```bash
    docker compose exec clickhouse-server clickhouse-client
    ```
2.  Пример запроса (внутри клиента):
    ```sql
    SELECT count() FROM orders_table;
    ```

### Взаимодействие с Kafka

1.  Получить интерактивный доступ к контейнеру Kafka:
    ```bash
    docker compose exec kafka bash
    ```
2.  Находясь внутри контейнера, можно выполнять команды:
      * **Посмотреть список топиков и их партиций:**
        ```bash
        kafka-topics.sh --bootstrap-server localhost:9092 --describe
        ```
      * **Посмотреть статус группы потребителей (узнать лаг):**
        ```bash
        kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group clickhouse_router_group
        ```


