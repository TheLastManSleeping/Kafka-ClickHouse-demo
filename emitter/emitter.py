import json
import time
import random
import os
from faker import Faker
from kafka import KafkaProducer

# Получаем желаемую скорость из переменной окружения.
TARGET_RATE_PER_SECOND = int(os.environ.get('MESSAGES_PER_SECOND', 10))
print(f"Целевая скорость: {TARGET_RATE_PER_SECOND} сообщений в секунду.")

# --- Конфигурация продюсера из переменных окружения ---
producer_config = {
    'bootstrap_servers': 'kafka:9092',
    'value_serializer': lambda v: json.dumps(v).encode('utf-8'),
    'batch_size': int(os.environ.get('PRODUCER_BATCH_SIZE', 16384 * 4)),
    'linger_ms': int(os.environ.get('PRODUCER_LINGER_MS', 5))
}

# Читаем настройку acks
acks_setting = os.environ.get('PRODUCER_ACKS', '1')
# 'all' в Kafka-python соответствует -1
if acks_setting.lower() == 'all':
    producer_config['acks'] = -1
else:
    producer_config['acks'] = int(acks_setting)


print(f"Конфигурация продюсера: {producer_config}")


# Инициализация продюсера Kafka с конфигурацией
producer = KafkaProducer(**producer_config)
fake = Faker()

# Определяем наши топики
TOPICS = {
    'user_clicks': lambda: {
        'user_id': fake.uuid4(),
        'element_id': f"btn-{random.randint(1, 20)}",
        'url': fake.uri(),
    },
    'page_views': lambda: {
        'user_id': fake.uuid4(),
        'url': fake.uri(),
        'duration_seconds': random.randint(5, 300),
    },
    'orders': lambda: {
        'order_id': fake.uuid4(),
        'user_id': fake.uuid4(),
        'amount': round(random.uniform(9.99, 999.99), 2),
    }
}

print("Event Emitter запущен. Отправка событий в несколько топиков...")

try:
    while True:
        start_time = time.time()
        messages_sent = 0

        # Отправляем пачку сообщений, равную целевой скорости
        for _ in range(TARGET_RATE_PER_SECOND):
            topic_name = random.choice(list(TOPICS.keys()))
            event_generator = TOPICS[topic_name]
            event = event_generator()
            event['timestamp'] = fake.date_time_this_decade().strftime('%Y-%m-%d %H:%M:%S')
            event['ip_address'] = fake.ipv4()
            producer.send(topic_name, value=event)
            messages_sent += 1

        # Ожидаем остаток секунды, чтобы выдержать скорость
        end_time = time.time()
        elapsed_time = end_time - start_time
        sleep_time = 1.0 - elapsed_time
        
        if sleep_time > 0:
            time.sleep(sleep_time)
        
        # Печатаем фактическую производительность
        actual_rate = messages_sent / (time.time() - start_time)
        print(f"Отправлено {messages_sent} сообщений. Фактическая скорость: {actual_rate:.0f} сообщ/сек")

except KeyboardInterrupt:
    print("Остановка Event Emitter...")
finally:
    producer.flush()
    producer.close()
    print("Продюсер Kafka закрыт.")