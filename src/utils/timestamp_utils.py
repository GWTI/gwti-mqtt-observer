from datetime import datetime

def parse_timestamp(ts):
    """Parse timestamp string or Unix timestamp into YYMMDD-HHMMSS format."""
    if isinstance(ts, (int, str)) and str(ts).isdigit():  # Handle Unix timestamp
        try:
            # Convert to integer and assume seconds
            timestamp_obj = datetime.fromtimestamp(int(ts))
        except ValueError:
            raise ValueError(f"Invalid Unix timestamp: {ts}")
    else:
        # Try parsing as formatted date string
        try:
            timestamp_obj = datetime.strptime(ts, '%Y-%m-%d %H:%M:%S.%f')
        except ValueError:
            try:
                timestamp_obj = datetime.strptime(ts, '%Y-%m-%d %H:%M:%S')
            except ValueError:
                raise ValueError(f"Unrecognized timestamp format: {ts}")

    # Format as YYMMDD-HHMMSS
    return timestamp_obj.strftime('%y%m%d-%H%M%S')
