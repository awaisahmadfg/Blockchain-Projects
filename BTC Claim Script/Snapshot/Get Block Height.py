import requests
import datetime
import pytz

# Function to convert a UTC timestamp to a local date in a specific time zone
def timestamp_to_local_date(timestamp, local_tz):
    utc_time = datetime.datetime.utcfromtimestamp(timestamp)
    utc_time = utc_time.replace(tzinfo=pytz.utc)
    local_time = utc_time.astimezone(local_tz)
    return local_time.date()

# Function to fetch block information
def get_block_info(block_height):
    api_endpoint = f"https://blockchain.info/block-height/{block_height}?format=json"
    response = requests.get(api_endpoint)
    if response.status_code == 200:
        return response.json()
    else:
        return None

# Starting block height (the last block on December 23, 2023)
start_block_height = 822434

# Initialize variables
current_block_height = start_block_height
target_date = datetime.date(2023, 12, 22)
local_tz = pytz.timezone('Asia/Karachi')  # Adjust the timezone as per your location

print("Block heights for December 22, 2023, GMT +5:")

# Traverse blocks in reverse
while True:
    block_info = get_block_info(current_block_height)
    if not block_info:
        print(f"Failed to fetch data for block height: {current_block_height}")
        break

    block_timestamp = block_info['blocks'][0]['time']
    block_date = timestamp_to_local_date(block_timestamp, local_tz)

    if block_date < target_date:
        # We have passed the target date
        break
    elif block_date == target_date:
        # This block is on the target date, print it immediately
        print(current_block_height)

    # Move to the previous block
    current_block_height -= 1
