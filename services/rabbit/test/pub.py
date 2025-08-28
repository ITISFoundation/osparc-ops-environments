import logging
import os
import time

import pika

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger(__name__)

host = os.environ["RABBIT_HOSTS"].strip()
credentials = pika.PlainCredentials(
    os.environ["RABBIT_USER"], os.environ["RABBIT_PASS"]
)
parameters = pika.ConnectionParameters(
    host=host,
    port=5672,
    credentials=credentials,
    client_properties={"connection_name": "publisher"},
)

while True:
    connection = pika.BlockingConnection(parameters)
    try:
        channel = connection.channel()

        logger.info("Queue 'hello' (quorum) deklarieren...")
        channel.queue_declare(
            queue="hello", durable=True, arguments={"x-queue-type": "quorum"}
        )

        for i in range(10_000):
            msg = f"Nachricht {i}"
            channel.basic_publish(
                exchange="",
                routing_key="hello",
                body=msg,
                properties=pika.BasicProperties(delivery_mode=2),
            )
            logger.info(f"Gesendet: {msg}")
            time.sleep(3)
    except Exception:
        logger.error(
            "Verbindung zum RabbitMQ Broker wurde geschlossen. Versuche erneut zu verbinden..."
        )
        time.sleep(1)
