import base64
import json
from src.extract_metadata import extract_metadata, send_metadata_to_dynamo
from src.process_zip_data import process_zip_data
from src.sqs_service import send_to_queue



def lambda_handler(event, context):
    print(f"event: {event}")

    # Decode the data
    byte_list_data = event['data']
    decoded_data = base64.b64decode(byte_list_data)

    # Step 1: Extract metadata and send to DynamoDB
    timestamp, datasource = extract_metadata(decoded_data)
    if not timestamp or not datasource:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Failed to extract metadata from ZIP file."})
        }

    send_metadata_to_dynamo(timestamp, datasource, byte_list_data)

    # Step 2: Process the ZIP file data
    timestamp, datasource, data_entries = process_zip_data(decoded_data)
    if not data_entries:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "No valid data entries found in ZIP file."})
        }

    # Step 3: Send data to SQS
    message = {
        "timestamp": timestamp,
        "datasource": datasource,
        "entries": data_entries
    }
    print('message: ', message)

    sqs_response = send_to_queue(datasource, timestamp, message)
    print(f"SQS send response: {sqs_response}")

    

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "ZIP file processing finished."})
    }