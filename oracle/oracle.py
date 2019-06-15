from web3 import Web3, HTTPProvider. IPCProvider
import time, requests, json

with open("abi.json") as f:
    abi = json.load(f)

with open("password.txt") as f:
    password = f.read()

def get_etherprice():
    r = requests.get(url="https://api.coinmarketcap.com/v1/ticker/ethereum/")
    return float(r.json()[0]['price_usd'])

web3 = Web3(Web3.IPCProvider('/home/nuclaer/.ethereum/testnet/geth.ipc'))#HTTPProvider("http://localhost:8545"))

sync = web3.eth.syncing

def isSynced(sync):
    if sync==False:
        # is the block current?
        if abs(time.time()-web3.eth.getBlock(web3.eth.blockNumber).timestamp)<30:
            return True
        else:
            return False
    elif sync.highestBlock-1>sync.currentBlock:
        return False

if(not isSynced(sync)):
    print("Must wait for sync to complete...")
    while(not isSynced(sync)):
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

transactor = contract.transact({'from':web3.eth.accounts[0]})

def set_price(price_eth):
    web3.personal.unlockAccount(web3.eth.accounts[0],password, 15000)

print("Oracle main loop starting.")
while(True):
    pass#price = 
