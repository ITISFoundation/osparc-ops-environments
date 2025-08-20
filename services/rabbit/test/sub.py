import logging
import os
import random

import pika

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger(__name__)

hosts = os.environ["RABBIT_HOSTS"].split(",")
credentials = pika.PlainCredentials(os.getenv("RABBIT_USER"), os.getenv("RABBIT_PASS"))

hosts = os.environ["RABBIT_HOSTS"].split(",")
credentials = pika.PlainCredentials(os.getenv("RABBIT_USER"), os.getenv("RABBIT_PASS"))

endpoints = [
    pika.URLParameters(
        f"amqp://{credentials.username}:{credentials.password}@{h.strip()}:5672/"
    )
    for h in hosts
]

while True:
    logger.info(f"Verbinde zu RabbitMQ Hosts: {hosts}")

    random.shuffle(endpoints)
    try:
        connection = pika.BlockingConnection(endpoints)
        channel = connection.channel()

        logger.info("Queue 'hello' (quorum) deklarieren...")
        channel.queue_declare(
            queue="hello", durable=True, arguments={"x-queue-type": "quorum"}
        )

        def callback(ch, method, properties, body):
            logger.info(f"Empfangen: {body.decode()}")
            ch.basic_ack(delivery_tag=method.delivery_tag)

        channel.basic_consume(queue="hello", on_message_callback=callback)
        logger.info("Warte auf Nachrichten...")
        channel.start_consuming()
    except pika.exceptions.ConnectionClosedByBroker:
        logger.error(
            "Verbindung zum RabbitMQ Broker wurde geschlossen. Versuche erneut zu verbinden..."
        )
