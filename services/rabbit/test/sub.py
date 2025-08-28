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
    client_properties={"connection_name": "subscriber"},
)

while True:
    logger.info(f"Verbinde zu RabbitMQ Host: {host}")

    try:
        connection = pika.BlockingConnection(parameters)
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
    except Exception:
        logger.error(
            "Verbindung zum RabbitMQ Broker wurde geschlossen. Versuche erneut zu verbinden..."
        )
        time.sleep(1)
