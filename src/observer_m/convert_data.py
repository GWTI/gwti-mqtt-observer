def convert_data(data):
    try:
        numbers = list(map(int, data.split(",")))
        if len(numbers) > 1:
            return (
                numbers[0] * (2 ** 48) +
                numbers[1] * (2 ** 32) +
                numbers[2] * (2 ** 16) +
                numbers[3]
            )
        else:
            return float(data)
    except Exception as e:
        print(f"Error converting data: {e}")
        return data