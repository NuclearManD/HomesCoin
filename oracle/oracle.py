from web3 import Web3, HTTPProvider
import time

web3 = Web3(HTTPProvider("http://localhost:8545"))

sync = web3.eth.syncing

if(sync.highestBlock-1>sync.currentBlock):
    print("Must wait for sync to complete...")
    while(sync.highestBlock>sync.currentBlock):
        sync = web3.eth.syncing
        print("Block ",sync.currentBlock, " of ", sync.highestBlock," synced...")
        time.sleep(120) # wait two minutes

