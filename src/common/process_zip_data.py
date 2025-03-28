import io
import zipfile
import csv
from src.utils.extract_metadata import extract_metadata
from src.utils.dev_key_utils import get_dev_key
from src.utils.timestamp_utils import parse_timestamp

def process_zip_data(decoded_data):
    """Process the ZIP file and extract data entries."""
    timestamp, datasource = extract_metadata(decoded_data)
    if not timestamp or not datasource:
        return None, None, []

    zip_data = io.BytesIO(decoded_data)
    data_entries = []

    with zipfile.ZipFile(zip_data, 'r') as zip_ref:
        file_list = zip_ref.namelist()
        first_file_name = file_list[0]

        with zip_ref.open(first_file_name, 'r') as csv_file:
            csv_reader = csv.reader(io.TextIOWrapper(csv_file, 'utf-8'))
            for row in csv_reader:
                if not row or len(row) != 3:
                    continue

                tstamp, address, data = row
                timestamp_obj = parse_timestamp(tstamp)

                config_details = get_dev_key(datasource, address.strip())
                if not config_details:
                    continue

                dev_key = config_details.get('DevKey')
                attr_name = config_details.get('AttrName')

                if dev_key and attr_name:
                    telemetry = {
                        'ts': timestamp_obj,
                        'values': {attr_name: data.strip()}
                    }
                    data_entries.append({
                        "datasource": datasource,
                        "data": telemetry,
                        "DevKey": dev_key
                    })

    return timestamp, datasource, data_entries
