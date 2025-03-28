import json
import base64
import logging
from datetime import datetime, timezone
from src.utils.formate_date import format_date
from src.observer_m.convert_data import convert_data

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    print('event: ', event)

    print("1 Minute's Worth of Data:")

    for record in event['Records']:
        # Decode Kinesis data
        data = json.loads(base64.b64decode(record['kinesis']['data']).decode('utf-8'))
        print(data)

        formatted_date = format_date(data["date"])
        print('formatted_date: ', formatted_date)
        converted_data = convert_data(data["data"])
        print('converted_data: ', converted_data)
        modbus_address = data["Full modbus register address"]
        print('modbus_address: ', modbus_address)
    
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Data processed and logged'})
    }