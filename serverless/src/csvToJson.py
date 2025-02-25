import json
import zipfile
import io
import base64
import boto3
import os
import csv
import requests
from datetime import datetime

sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')
# queue_url = "https://sqs.eu-west-2.amazonaws.com/470851704113/Observer-MQTT-development-sendToTargetServer.fifo"  # Replace with your SQS Queue URL
# table_name = "Observer-MQTT-development-ObserverDataTable"  # Replace with your DynamoDB Table name
cache_table_name = "Observer-MQTT-development-DevKeyCache"  # Replace with your cache DynamoDB Table name

def get_dev_key(datasource, address):
    # First check if the DevKey is in the cache
    cached_devkey = get_dev_key_from_cache(datasource, address)
    print(f'cached_devkey: {cached_devkey}')
    if cached_devkey:
        print("DevKey found in cache")
        return cached_devkey
   
    encoded_datasource = requests.utils.quote(datasource)
    
    try:
        devkey_response = requests.get(
            f"https://ggm7y77lti.execute-api.eu-west-2.amazonaws.com/production/v1/point/access-token?serial={encoded_datasource}&address={address}"
        )
        devkey_response.raise_for_status()
        print('devkey_response: ', devkey_response.json())
        
        if devkey_response.text.strip():
            response_json = devkey_response.json()
            if 'DevKey' in response_json and 'AttrName' in response_json:
                store_dev_key_in_cache(datasource, address, response_json)
                return response_json  
            else:
                print(f"Incomplete response JSON: {response_json}")
        else:
            print("Empty response received from the API.")
    except requests.exceptions.HTTPError as http_err:
        print(f"HTTP error occurred: {http_err}")
    except requests.exceptions.RequestException as err:
        print(f"Request error occurred: {err}")
    except json.JSONDecodeError as json_err:
        print(f"JSON decode error: {json_err}")
    
    return None  

def get_dev_key_from_cache(datasource, address):
    # table = dynamodb.Table("Observer-MQTT-development-DevKeyCache")
    tableName = os.environ.get('DEVKEY_CACHE_TABLE_NAME', 'default_value')
    table = dynamodb.Table(tableName)
    try:
        response = table.get_item(
            Key={
                'serial': datasource,
                'address': address
            }
        )
        item = response.get('Item')
        if item:
            return item.get('data')  # Return devkey attribute if found
    except Exception as e:
        print(f"Error fetching item from DynamoDB: {e}")
    return None

def store_dev_key_in_cache(datasource, address, dev_key):
    tableName = os.environ.get('DEVKEY_CACHE_TABLE_NAME', 'default_value')
    table = dynamodb.Table(tableName)
    try:
        response = table.put_item(
            Item={
                'serial': datasource,
                'address': address,
                'data': dev_key
            }
        )
        # print(f"DevKey stored in cache for {datasource}_{address}")
    except Exception as e:
        print(f"Error storing item in DynamoDB: {e}")

def lambda_handler(event, context):
    print(f"event: {event}")

    table_name = os.environ.get('OBSERVER_DATA_TABLE_NAME', 'default_value')

    queue_url = os.environ.get('SEND_TO_TARGET_SERVER_QUEUE', 'default_value')
    print('queue_url: ', queue_url)
    byte_list_data = event['data']
    print(f"TYPE: {byte_list_data}")

    # Convert byte list back to binary data
    decoded_data = base64.b64decode(byte_list_data)
    print(f"decoded_data: {decoded_data}")

    zip_data = io.BytesIO(decoded_data)

    # Use zipfile.ZipFile to read the contents of the ZIP file
    with zipfile.ZipFile(zip_data, 'r') as zip_ref:
        # List the files in the ZIP archive
        file_list = zip_ref.namelist()
        print("Files in ZIP archive:", file_list)

        parts = file_list[0].split('-')

        timestamp = "-".join(parts[:2])
        datasource = parts[-1].split('.')[0][:-2]

        table = dynamodb.Table(table_name)
        response = table.put_item(
            Item={
                'timestamp': timestamp,
                'datasource': datasource,
                'sent': 'false',
                'data': byte_list_data
            }
        )

        # Extract the first file from the ZIP archive
        first_file_name = file_list[0]
        with zip_ref.open(first_file_name, 'r') as csv_file:
            csv_reader = csv.reader(io.TextIOWrapper(csv_file, 'utf-8'))

            data_entries = []
            for row in csv_reader:
                print('row: ', row)
                # Skip empty rows
                if not row or all(not cell.strip() for cell in row):
                    continue
                if len(row) != 3:
                    print(f"Unexpected row format: {row}")
                    continue   
                
                tstamp, address, data = row
                timestamp_obj = parse_timestamp(tstamp)

                config_details = get_dev_key(datasource, address.strip())


                if not config_details:
                    print(f"Failed to retrieve config details for row: {row}")
                    continue

                dev_key = config_details.get('DevKey')
                print('dev_key: ', dev_key)
                attr_name = config_details.get('AttrName')
                if dev_key and attr_name:
                    telemetry = {
                        'ts': timestamp_obj,
                        'values': {
                            attr_name: data.strip(),
                        },
                    }
                    data_entries.append({
                        "datasource": datasource,
                        "data": telemetry,
                        "DevKey": dev_key
                    })

        print('data_entries: ', data_entries)

        message = {
            "timestamp": timestamp,
            "datasource": datasource,
            "entries": data_entries
        }


        sqs_response = sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message),
            MessageGroupId=f"{timestamp}-{datasource}"
        )

        print(f"sqs send response: {sqs_response}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "zip file processing finished",
        }),
    }

def parse_timestamp(ts):
    try:
        timestamp_obj = datetime.strptime(ts, '%Y-%m-%d %H:%M:%S.%f')
    except ValueError:
        timestamp_obj = datetime.strptime(ts, '%Y-%m-%d %H:%M:%S')
        timestamp_obj = timestamp_obj.replace(microsecond=0)
    
    return int(timestamp_obj.timestamp() * 1000)
