import os
import boto3
import json


sqs = boto3.client('sqs')


def send_to_queue(datasource, timestamp, message, dev_key=None):
    queue_url = os.environ.get('SEND_TO_TARGET_SERVER_QUEUE', 'default_value')

    if dev_key is None:
        dev_key = message['entries'][0]['DevKey']

    sqs_response = sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(message),
        MessageGroupId=f"{timestamp}-{datasource}-{dev_key}"

    )

    print(f"sqs send response: {sqs_response}")

    return sqs_response
