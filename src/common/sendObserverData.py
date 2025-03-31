import json
import requests
import os
from urllib.parse import quote, unquote
from datetime import datetime

# Define API Gateway URLs for different stages
API_URLS = {
    'development': 'https://ofoeavfqk2.execute-api.eu-west-2.amazonaws.com/development/v1',
    'qa': 'https://9df6suxbo4.execute-api.eu-west-2.amazonaws.com/qa/v1',
    'production': 'https://ggm7y77lti.execute-api.eu-west-2.amazonaws.com/production/v1'
}


def get_api_base_url():
    """Get the appropriate API base URL based on the current stage."""
    stage = os.environ.get('STAGE', 'development')
    print('stage: ', stage)
    return API_URLS.get(stage, API_URLS['development'])


def get_url(serial):
    encoded_serial = requests.utils.quote(serial)
    base_url = get_api_base_url()
    print('base_url: ', base_url)
    try:
        url_response = requests.get(
            f"{base_url}/csm/target-url?serial={encoded_serial}")
        print('url_response: ', url_response)
        url_response.raise_for_status()
        response_json = url_response.json()
        print('response_json: ', response_json)

        # Check if both "url" and "custom_header" keys exist in the API response
        url = response_json.get("url")
        custom_header = response_json.get("custom_header")

        if url is not None:
            return {"url": url, "custom_header": custom_header}
        else:
            print("Expected keys not found in the API response.")
            return None
    except requests.exceptions.HTTPError as http_err:
        print(f"HTTP error occurred: {http_err}")  # HTTP error
    except requests.exceptions.RequestException as err:
        print(f"Error occurred: {err}")  # Other errors
    except json.JSONDecodeError as json_err:
        print(f"JSON decode error: {json_err}")  # JSON decode error
    return None


def lambda_handler(event, context):
    print(f"event: {event}")

    body = event['Records'][0]['body']
    data = json.loads(body)
    print('data: ', data)

    # Define headers for the POST request
    headers = {'Content-Type': 'application/json'}

    serial = data.get('datasource')
    print('serial: ', serial)

    result = get_url(serial)
    print('result: ', result)

    if result:
        url = result['url']
        print('url: ', url)
        custom_header = result.get('custom_header')
        print('custom_header: ', custom_header)

        if custom_header:
            headers['X-Custom-Header'] = custom_header
    else:
        print("Failed to retrieve URL from get_url.")
        return {
            'statusCode': 500,
            'body': json.dumps('Failed to retrieve URL.')
        }

    print('headers: ', headers)
    print(f'{url}/api/v1/MQTT-Ingress/telemetry')

    # Send the JSON data to the specified endpoint
    resp = requests.post(
        f'{url}/api/v1/MQTT-Ingress/telemetry', headers=headers, json=data)
    
    # if serial == 'a1F5':
    #     extra_resp = requests.post(
    #         f'http://10.0.3.191:6587/mqtt', headers=headers, json=data)
        
    #     if extra_resp.status_code == 200:
    #         print("EXTRA Data sent successfully:")
    #     else:
    #         print(
    #             f"EXTRA Failed to send data. Status code: {extra_resp.status_code}, Response: {extra_resp.text}")

    if serial == 'a1F5':
        extra_resp = requests.post(
            f'http://10.0.3.191:6587/mqtt', headers=headers, json=data)

        if extra_resp.status_code == 200:
            print("EXTRA Data sent successfully:")
        else:
            print(
                f"EXTRA Failed to send data. Status code: {extra_resp.status_code}, Response: {extra_resp.text}")

    # Check the response
    if resp.status_code == 200:
        print("Data sent successfully:")
    else:
        print(
            f"Failed to send data. Status code: {resp.status_code}, Response: {resp.text}")

    return {
        'statusCode': 200,
        'body': json.dumps('Data processed successfully!')
    }
