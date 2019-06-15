from web3 import Web3, HTTPProvider, IPCProvider
import time, requests, json

# basic configuration
contract_adr = "0x9E405115F9992BE0D0bFF2cCc81Eb647dABB74E4"
price_target = 1000.0 # in USD
swing_amount = 100

with open("abi.json") as f:
    abi = json.load(f)

with open("password.txt") as f:
    password = f.read()
    while password.endswith('\n') or password.endswith('\r'):
        password = password[:-1]

def get_etherprice():
    r = requests.get(url="https://api.coinmarketcap.com/v1/ticker/ethereum/")
    return float(r.json()[0]['price_usd'])

web3 = Web3(Web3.IPCProvider('/home/nuclaer/.ethereum/testnet/geth.ipc'))#HTTPProvider("http://localhost:8545"))

sync = web3.eth.syncing

def isSynced(sync):
    if sync==False:
        # is the block current?
        if abs(time.time()-web3.eth.getBlock(web3.eth.blockNumber).timestamp)<120:
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

print("Connecting contract ["+contract_adr+"]")

contract = web3.eth.contract(address=contract_adr, abi=abi)

transactor = contract.transact({'from':web3.eth.accounts[0]})
caller = contract.call()

def set_price(price_eth):
    web3.personal.unlockAccount(web3.eth.accounts[0],password, 5) # give us 5 seconds to send the transaction
    return transactor.setPrice(round(price_eth*10000))
def get_price():
    return caller.base_price()/10000.0

# sleep without preventing ctrl-c breaks
def smartsleep(seconds):
    tea_time = seconds+time.time()
    while tea_time>time.time():
        time.sleep(.1)

print("Oracle main loop starting.")
print("Token price at start: $", get_price()*get_etherprice())
smartsleep(5)
while(True):
    # get etherprice once per tick to avoid spamming the price api server
    ether_price = get_etherprice()
    token_price = get_price()*ether_price

    if abs(token_price - price_target)>swing_amount:
        print("Changing token price from $", token_price, " to $", price_target, "...")
        transaction = set_price(price_target/ether_price)
        print("Transaction hash is ", hex(int.from_bytes(transaction, 'big')))
        try:
            web3.eth.waitForTransactionReceipt(transaction, 180)
            print("Complete.  New price is $", get_price()*get_etherprice())
        except:
            print("Transaction recept not received; transaction probably dropped.")
            print("Trying again...")
            ook()
    else:
        smartsleep(180)
