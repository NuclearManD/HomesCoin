from web3 import Web3, HTTPProvider, IPCProvider
import time, requests, json

# basic configuration
contract_adr = "0x1574Ea34e90db0618c343E6E64a31e03c40383c9"
etherbase = "0x37816524091AB70755f2B943fa194B3C407373e2"
price_target = 1000.0 # in USD
swing_amount = 5

with open("abi.json") as f:
    abi = json.load(f)

with open("password.txt") as f:
    password = f.read()
    while password.endswith('\n') or password.endswith('\r'):
        password = password[:-1]

def get_etherprice():
    while True:
        try:
            r = requests.get(url="https://api.coinmarketcap.com/v1/ticker/ethereum/")
            return float(r.json()[0]['price_usd'])
        except:
            print("Failed to get price, trying again...")

web3 = Web3(Web3.IPCProvider('/home/nuclear/.ethereum/geth.ipc'))#HTTPProvider("http://localhost:8545"))

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

transactor = contract.transact({'from':etherbase})
caller = contract.call()

def set_price(price_eth):
    web3.personal.unlockAccount(etherbase,password, 5) # give us 5 seconds to send the transaction
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
        try:
            transaction = set_price(price_target/ether_price)
            print("Transaction hash is ", hex(int.from_bytes(transaction, 'big')))
            try:
                web3.eth.waitForTransactionReceipt(transaction, 1800) # up to 30 minutes
                print("Complete.  New price is $", get_price()*get_etherprice())
            except:
                print("Transaction recept not received; transaction probably dropped.")
                print("Trying again...")
                ook()
        except ValueError as e:
            print(e.args[0]['message'])
            print('recheck in 20 minutes')
            smartsleep(60*20)
            print("Token price is now $", get_price()*get_etherprice())
    else:
        smartsleep(180)
        print("Token price is now $", get_price()*get_etherprice())
