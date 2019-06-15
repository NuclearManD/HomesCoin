# Important Information (For those already familiar with HomesCoin)

## Oracle Program Requirements

The oracle program currently must be modified to change the configuration.  This may be fixed in the future, however.

Additionally, the oracle program is built to run on Python 3 with web3.py version 4.9.2 or higher, however it may work on lower versions.  Installing web3 with `sudo pip3 install web3` does NOT work.  Install from source.
### Installing web3.py from source
 * download web3.py source and extract it
 * in the root of the project execute `sudo pip3 install .`
 * You're done!

# About HomesCoin

HomesCoin is a cryptocurrency and decentralized database focused on real estate, which allows quick and seamless buying of homes.

As a cryptocurrency, it can be bought, sold, and transferred without a third party.  Most transfers complete within 8 to 30 seconds, and are thus far faster than any large bank transfer.  The time taken to complete a transfer does not increase with larger transactions either, so expensive homes can be paid for just as fast as a cup of coffee.

As a decentralized database, it functions as a way to store information about houses online.  Unlike centralized databases, it cannot be taken offline, and it can be accessed from anywhere.  The information on the database is still trustworthy however, because only the controlling account of the HOM Coin Inc. can add or modify entries in this database.

Unlike most other cryptocurrencies, the HOM coin has a fixed price.  Nobody wants to sell a home with other cryptocurrencies because they don't know what the currency will be worth when the buy completes.  HOM  solves this problem.  Each HOM coin is worth $1000.
## How is the coin implemented?
The HOM coin exists through an Ethereum smart contract, so it inherits the security of an enormous blockchain but can still be engineered to meet requirements.  The HOM coin is an ERC20 token, so it can be transferred using any Ethereum wallet.  It can also be transferred and managed from computer programs that interface directly with the blockchain.
## How is the database implemented?
The HomesCoin database exists as a collection of Ethereum transactions.  When data about a house is created or modified, an Ethereum transaction is sent to the HOM coin smart contract.  Cumulatively these transactions form the data in the database, and they can be scanned to get the data about a house.  It also records every change ever made to the data in the database, so a history can be kept.

Only the HOM coin contract owner can update the database, but the information on the database is publicly accessible.
How is the coin kept stable?
HomesCoin has the ability to be its own exchange, where the price is set at a certain amount of Ethereum.  A user can convert Ethereum to HomesCoin (or vice versa) through the HomesCoin smart contract.  The price of ethereum changes though, so the price in ethereum has to change to keep the price in dollars stable.  To handle this, the price can be changed by an oracle program.  Each buy or sell executed on the contract has a very small fee which is sent to this oracle program.  This program watches the price of Ethereum and ensures that the HomesCoin price is $1000 constantly.

This small fee is less than a cent, but multiple buys and sells provides the oracle program enough Ethereum to function.  The oracle only needs a few cents to change the price.  The oracle needs that few cents to pay Ethereum's transaction fees.  As the oracle program gets more funds, the fee drops.  Once the oracle program has a certain amount of Ethereum, the fee is fractions of fractions of cents.  This cutoff would only be worth a few dollars, so it would be met very quickly if there were even small amounts of trading volume on the HomesCoin smart contract.

If any exchange tried to sell HomesCoin at a different price then traders would take advantage of the opportunity, and buy from the cheaper source and sell to the more expensive one, correcting the market.

If the HomesCoin smart contract ran out of HomesCoin or Ethereum, the price would be able to change, but not for long.  HomesCoins can be minted or destroyed, so the market can be inflated or deflated.  This shouldn't be needed because the HomesCoin contract would have very very large amounts of HomesCoin, and selling it would give it very large amounts of Ethereum.
## Security
HomesCoin exists on the Ethereum blockchain, so it has the same level of security Ethereum does.  Hypothetically, there could be a bug in the smart contract that would make it vulnerable to attack, but this is extremely unlikely.  The prototype HomesCoin contract has already been through many test versions, and the most sensitive logic is very simple, so has less room for security holes.  The biggest security risk is the HomesCoin controlling account.  If an attacker gains access to the account, they would have complete control of the token.  This can be avoided by storing the account on a hardware wallet with a password.  At that point the attacker would need to physically locate and steal the hardware wallet, then obtain the password.  This effort is nearly impossible.

The next biggest hole is the oracle program, which controls the token price.  This program has an Ethereum account as well, but it cannot be put on a hardware wallet.  The oracle program needs untethered access to the Ethereum account.  The easiest way of attacking this program is by attempting to disconnect it from the Ethereum network, making price updates impossible.  This can be mitigated easily my moving the oracle program to another machine that can communicate with the Ethereum network.  The oracle program should be running on a computer that cannot be accessed from the internet at all.  The computer cannot have any remote desktop software, SSH, HTTP server, and preferably no servers at all.  Attackers will not be able to access the computer any way other than physically.  The oracle account would have a password too, so even if the computer is accessed, the password would need to be broken.  Breaking passwords is not a trivial task.

The Ethereum blockchain is completely secured.  A transaction cannot be made without signing from a private key, so an account cannot be accessed without a private key.  The blockchain itself has, to my knowledge, never been hacked.  Smart contracts on the blockchain have been hacked, but this is rare and requires the contract to have a security hole.
