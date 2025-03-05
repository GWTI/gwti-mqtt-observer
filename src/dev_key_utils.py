import requests
import boto3
import os
import json

dynamodb = boto3.resource('dynamodb')

def get_dev_key(datasource, address):
    print('address: ', address)
    print('datasource: ', datasource)
    """Fetch DevKey from cache or API."""
    cached_devkey = get_dev_key_from_cache(datasource, address)
    print('cached_devkey: ', cached_devkey)
    if cached_devkey:
        return cached_devkey

    encoded_datasource = requests.utils.quote(datasource)
    try:
        devkey_response = requests.get(
            f"https://ggm7y77lti.execute-api.eu-west-2.amazonaws.com/production/v1/point/access-token?serial={encoded_datasource}&address={address}"
        )
        devkey_response.raise_for_status()
        response_json = devkey_response.json()

        if 'DevKey' in response_json and 'AttrName' in response_json:
            store_dev_key_in_cache(datasource, address, response_json)
            return response_json
    except requests.exceptions.RequestException as err:
        print(f"Request error occurred: {err}")
    except json.JSONDecodeError as json_err:
        print(f"JSON decode error: {json_err}")
    return None

def get_dev_key_from_cache(datasource, address):
    """Fetch DevKey from DynamoDB cache."""
    table_name = os.environ.get('DEVKEY_CACHE_TABLE_NAME', 'default_value')
    table = dynamodb.Table(table_name)
    try:
        response = table.get_item(
            Key={
                'serial': datasource,
                'address': address
            }
        )
        return response.get('Item', {}).get('data')
    except Exception as e:
        print(f"Error fetching item from DynamoDB: {e}")
    return None

def store_dev_key_in_cache(datasource, address, dev_key):
    """Store DevKey in DynamoDB cache."""
    table_name = os.environ.get('DEVKEY_CACHE_TABLE_NAME', 'default_value')
    table = dynamodb.Table(table_name)
    try:
        table.put_item(
            Item={
                'serial': datasource,
                'address': address,
                'data': dev_key
            }
        )
    except Exception as e:
        print(f"Error storing item in DynamoDB: {e}")