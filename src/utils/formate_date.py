def format_date(date_str):
    try:
        date_part, time_part = date_str.split(" ")
        day, month, year = date_part.split("/")
        return f"{year}-{month}-{day} {time_part}"
    except Exception as e:
        print(f"Error formatting date: {e}")
        return date_str