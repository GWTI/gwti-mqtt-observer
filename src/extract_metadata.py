import base64
import io
import zipfile
import boto3
import os

dynamodb = boto3.resource('dynamodb')

def extract_metadata(decoded_data):
    """Extract timestamp and datasource from the ZIP file name."""
    zip_data = io.BytesIO(decoded_data)

    with zipfile.ZipFile(zip_data, 'r') as zip_ref:
        file_list = zip_ref.namelist()
        if not file_list:
            print("ZIP file is empty.")
            return None, None

        # Extract parts, timestamp, and datasource from the filename
        parts = file_list[0].split('-')
        timestamp = "-".join(parts[:2])
        datasource = parts[-1].split('.')[0][:-2]

    return timestamp, datasource

def send_metadata_to_dynamo(timestamp, datasource, byte_list_data):
    """Send metadata (timestamp, datasource) to DynamoDB."""
    table_name = os.environ.get('OBSERVER_DATA_TABLE_NAME', 'default_value')
    table = dynamodb.Table(table_name)

    response = table.put_item(
        Item={
            'timestamp': timestamp,
            'datasource': datasource,
            'sent': 'false',
            'data': byte_list_data
        }
    )
    return response