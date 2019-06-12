from web3 import Web3, HTTPProvider
import time, requests, json

with open("abi.json") as f:
    info_json = json.load(f)
abi = info_json

def get_etherprice():
    r = requests.get(url="https://api.coinmarketcap.com/v1/ticker/ethereum/")
    return float(r.json()[0]['price_usd'])

web3 = Web3(HTTPProvider("http://localhost:8545"))

sync = web3.eth.syncing

if(sync==False or sync.highestBlock-1>sync.currentBlock):
    print("Must wait for sync to complete...")
    while(sync==False or sync.highestBlock>sync.currentBlock):
        sync = web3.eth.syncing
        if sync==False:
            print("Not yet syncing...")
        else:
            print("Block ",sync.currentBlock, " of ", sync.highestBlock," synced...")
        time.sleep(120) # wait two minutes
    print("Sync complete.")

contract_adr = "0x9e405115f9992be0d0bff2ccc81eb647dabb74e4"
print("Connecting contract ["+contract_adr+"]")

contract = web3.eth.contract(address=contract_adr, abi=abi)

print("Oracle main loop starting.")
while(True):
    pass#price = 
