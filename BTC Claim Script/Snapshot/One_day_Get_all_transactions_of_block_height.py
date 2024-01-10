import requests
import datetime
import pytz
import pandas as pd

# Function to convert a UTC timestamp to a local date in a specific time zone
def timestamp_to_local_date(timestamp, local_tz):
    utc_time = datetime.datetime.utcfromtimestamp(timestamp)
    utc_time = utc_time.replace(tzinfo=pytz.utc)
    local_time = utc_time.astimezone(local_tz)
    return local_time.date()

# Function to fetch block information using blockchain.info API
def get_block_info(block_height):
    api_endpoint = f"https://blockchain.info/block-height/{block_height}?format=json"
    response = requests.get(api_endpoint)
    if response.status_code == 200:
        return response.json()
    else:
        return None

# Function to fetch transactions for a block using Blockchair API
def fetch_transactions_for_block_blockchair(block_hash):
    url = f"https://api.blockchair.com/bitcoin/raw/block/{block_hash}"
    response = requests.get(url)
    if response.status_code == 200:
        try:
            data = response.json().get('data', {})
            block_data = data.get(block_hash, {}).get('decoded_raw_block', {})
            transactions = block_data.get('tx', [])
            return transactions
        except ValueError:
            print("Error decoding JSON")
            return []
    else:
        print(f"Failed to fetch transactions for block {block_hash}, status code: {response.status_code}")
        return []

# Starting block height (example: last block of the day on December 23, 2023)
start_block_height = 822434

# Initialize variables
current_block_height = start_block_height
target_date = datetime.date(2023, 12, 22)
local_tz = pytz.timezone('Asia/Karachi')

transaction_data = []

# Traverse blocks in reverse
while True:
    block_info = get_block_info(current_block_height)
    if not block_info:
        break

    block_timestamp = block_info['blocks'][0]['time']
    block_date = timestamp_to_local_date(block_timestamp, local_tz)

    if block_date < target_date:
        break
    elif block_date == target_date:
        block_hash = block_info['blocks'][0]['hash']
        transactions = fetch_transactions_for_block_blockchair(block_hash)
        for txid in transactions:
            transaction_data.append([current_block_height, block_hash, txid])

    current_block_height -= 1

# Create a DataFrame from the collected transaction data
df = pd.DataFrame(transaction_data, columns=['Block Height', 'Block Hash', 'Transaction ID'])

# Displaying DataFrame without the first record
pd.set_option('display.max_rows', None)
display(df.iloc[1:])
