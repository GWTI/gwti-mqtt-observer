def pad_timestamp(timestamp):

    ts_str = str(timestamp)
    

    current_length = len(ts_str)
    if current_length >= 13:
        return ts_str  
    

    zeros_to_add = 13 - current_length
    

    padded_ts = int(ts_str + '0' * zeros_to_add)
    
    return padded_ts