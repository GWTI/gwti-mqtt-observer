import json
import boto3
from src.utils.dev_key_utils import get_dev_key
from src.utils.timestamp_utils import parse_timestamp
from src.sqs.sqs_service import send_to_queue

sqs = boto3.client('sqs')

def lambda_handler(event, context):
    print(f"event: {event}")
    print(f"type: {type(event)}")
    data_entries = []

    try:
        # Ensure event is a list with at least one item
        if not event or not isinstance(event, list):
            raise ValueError("Event is empty or not a list")

        record = event[0]
        datasource = record.get('DS', '')
        address = record.get('address', '')
        timestamp = record.get('TS', '')  
        data = record.get('data', '')

        print(f"datasource: {datasource}")
        print(f"address: {address}")
        print(f"timestamp: {timestamp}")
        print(f"data: {data}")

        timestamp_obj = parse_timestamp(timestamp)
        print(f"timestamp_obj: {timestamp_obj}")

        # Convert address to string and strip if necessary
        address_str = str(address).strip()
        print('address_str: ', address_str)
        config_details = get_dev_key(datasource, address_str)
        print(f"config_details: {config_details}")
        if not config_details:
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "Failed to get config details"})
            }

        dev_key = config_details.get('DevKey')
        attr_name = config_details.get('AttrName')
        print(f"dev_key: {dev_key}")
        print(f"attr_name: {attr_name}")

        if dev_key and attr_name:
            telemetry = {
                'ts': timestamp,
                'values': {attr_name: data.strip()}
            }
            data_entries.append({
                "datasource": datasource,
                "data": telemetry,
                "DevKey": dev_key
            })

        print('data_entries: ', data_entries)
        message = {
            "timestamp": timestamp_obj,
            "datasource": datasource,
            "entries": data_entries
        }
        print(f"message: {message}")

        sqs_response = send_to_queue(datasource, timestamp, message)
        print(f"SQS send response: {sqs_response}")

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Observer M handler process finished"})
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }