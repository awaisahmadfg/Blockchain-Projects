import json
import requests
import logging

logging.captureWarnings(True)

print("Hello User!")
print("This program will use the Blockchain.info API to retrieve any unspent outputs for a given bitcoin address")

# Hardcoded Bitcoin address
address = "bc1qxhmdufsvnuaaaer4ynz88fspdsxq2h9e9cetdj"  # Replace with your desired address

try:
    # Send request to blockchain.info API
    resp = requests.get(f'https://blockchain.info/unspent?active={address}')
    resp.raise_for_status()  # Check for HTTP errors

    # Attempt to decode JSON
    data = resp.json()
    utxo_list = data["unspent_outputs"]

    print("\nFORMAT: [ Transaction ID : Index Number - Balance available to spend (in BTC) ]\n")

    total = 0
    for utxo in utxo_list:
        value_btc = float(utxo['value']) / 100000000
        print(f"{utxo['tx_hash']}:{utxo['tx_output_n']} - {value_btc} BTC\n")
        total += utxo['value']

    print(f"Total BTC available to spend: {total / 100000000} BTC")
    print("------")

except requests.HTTPError as e:
    # Handle HTTP errors
    print(f"HTTP Error: {e}")
except json.JSONDecodeError:
    # Handle JSON decode error
    print("Error decoding JSON from response")
except KeyError:
    # Handle missing keys in JSON data
    print("Missing expected data in JSON response")
except Exception as e:
    # Handle other exceptions
    print(f"An error occurred: {e}")
