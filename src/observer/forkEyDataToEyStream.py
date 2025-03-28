import json
import zipfile
import io
import base64
import boto3
import os
import csv
from datetime import datetime

iot_client_us_region = boto3.client("iot-data", region_name="us-east-1")


def lambda_handler(event, context):
    print(f"event: {event}")

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

        # Extract the first file from the ZIP archive
        first_file_name = file_list[0]
        with zip_ref.open(first_file_name, 'r') as csv_file:
            csv_reader = csv.reader(io.TextIOWrapper(csv_file, 'utf-8'))

            telemetry_list = []
            for row in csv_reader:
                print('row: ', row)
                # Skip empty rows
                if not row or all(not cell.strip() for cell in row):
                    continue
                if len(row) != 3:
                    print(f"Unexpected row format: {row}")
                    continue

                tstamp, address, data = row
                tsString = tstamp.split('.')[0] + ' UTC'

                telemetry_list.append({
                    'dateTime': tsString,
                    'address': address.strip(),
                    'value': data.strip(),
                })

        print('telemetry_list: ', telemetry_list)

        message = {
            "dataSource": {
                "id": datasource,
                "telemetryList": telemetry_list
            }
        }

        topic = os.environ.get('EY_FORK_MQTT_TOPIC', 'default_value')
        topic = f"{topic}/{datasource}"

        print(f"Publishing message to topic: {topic}")

        response = iot_client_us_region.publish(
            topic=topic,
            qos=1,  # Quality of Service level (0 or 1)
            payload=json.dumps(message)
        )

        print(f"Message sent successfully: {response}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "zip file processing finished",
        }),
    }
