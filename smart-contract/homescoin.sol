pragma solidity ^0.5.1;

contract ERC20Interface {
	function totalSupply() public view returns (uint);
	function balanceOf(address tokenOwner) public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract HomesCoin is ERC20Interface {

	string public symbol;
	string public  name;
	uint8 public decimals;
	uint _totalSupply;
	
	uint public base_price;			// base price in 1/10000 ether
	uint public min_fee;			// min fee for trades
	uint public fee_div;			// divisor for the fee
	uint public min_balance;		// minimum balance for the fee acceptor account
	
	address payable public oracle_adr;	// address to send fees to
	
	address payable public owner;
	address payable public database_owner;

	mapping(address => uint) public balances;
	mapping(address => mapping(address => uint)) allowed;

	// ------------------------------------------------------------------------
	// Constructor
	// ------------------------------------------------------------------------
	constructor(address payable token_owner, address payable db_owner) public {
		symbol = "HOM";
		name = "HOM Coin";
		decimals = 18;
		_totalSupply = 10000000 * 10**uint(decimals);
		owner = token_owner;
		database_owner = db_owner;
		balances[address(this)] = _totalSupply;
		emit Transfer(address(0), owner, _totalSupply);
		base_price=100000;
		oracle_adr = address(uint160(owner));
		min_balance = .02 ether;
		fee_div = 100;
		min_fee = .000001 ether;
		oracle_change_ready = true; // ensure that the owner can set the oracle address appropriately.
	}

	function totalSupply() public view returns (uint) {
		return _totalSupply;
	}
	
	function getCirculatingSupply() public view returns (uint) {
	    return _totalSupply - balances[address(this)];
	}
	
	uint public lastTradedPrice = 0;

	function balanceOf(address tokenOwner) public view returns (uint balance) {
		return balances[tokenOwner];
	}

	function transfer(address to, uint tokens) public returns (bool success) {
	    require(msg.data.length >= 64 + 4);
		require(to!=address(0));
		require(tokens<=balances[msg.sender]);
		require(balances[msg.sender]>balances[msg.sender] - tokens, "sender balance overflows"); // prevent overflows
		require(balances[to]< balances[to] + tokens, "receiver balance overflows"); // prevent overflows
		balances[msg.sender] = balances[msg.sender] - tokens;
		balances[to] = balances[to] + tokens;
		emit Transfer(msg.sender, to, tokens);
		return true;
	}

	function approve(address spender, uint tokens) public returns (bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
	    require(msg.data.length >= 96 + 4);
		require(to!=address(0));
		require(balances[from]>=tokens);
		require(allowed[from][msg.sender]>=tokens);
		
		require(balances[from]>balances[from] - tokens, "from balance overflows"); // prevent overflows
		require(balances[to]< balances[to] + tokens, "receiver balance overflows"); // prevent overflows
		require(allowed[from][msg.sender] > allowed[from][msg.sender] - tokens, "allowance overflows"); // prevent overflows
		
		balances[from] = balances[from] - tokens;
		allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
		balances[to] = balances[to] + tokens;
		emit Transfer(from, to, tokens);
		return true;
	}

	function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}
	
	event OfferCreateEvent(uint64 offer_id, uint64 houseid, uint8 day, uint8 month, uint16 year, uint64 price, string source, uint16 escrow_unix_time);
	event OfferCancelEvent(uint64 offer_id);
	
	event OfferAcceptEvent(uint64 offer_id);
	event BuyCancelEvent(uint64 offer_id);
	
	event OwnershipTransfer(uint64 offer_id);
	
	mapping(uint64=>string) public addresses;
	mapping(uint64=>uint32) public sqfts;
	mapping(uint64=>uint8) public bedrooms;
	mapping(uint64=>uint8) public bathrooms;
	mapping(uint64=>uint8) public house_type;
	mapping(uint64=>uint16) public year_built;
	mapping(uint64=>uint32) public lot_size;
	mapping(uint64=>uint64) public parcel_num;
	mapping(uint64=>uint32) public zipcode;
	
	uint64 public num_houses = 0;
	
	mapping(uint64=>string) public offer_src;
	mapping(uint64=>uint64) public offer_house;
	mapping(uint64=>uint256) public offer_price;
	mapping(uint64=>uint64) public offer_escrow_end_unix_time;
	mapping(uint64=>uint64) public offer_escrow_unix_time;
	mapping(uint64=>address payable) public offer_recipient;
	mapping(uint64=>address payable) public offer_acceptor;
	
	uint64 public num_offers = 0;
	
	// price is in 1e-18 HOM Coin (same units as transfer(), mint(), buy(), sell(), etc)
	function makeOffer(uint64 houseid, uint8 day, uint8 month, uint16 year, uint256 price, string memory source, uint16 escrow_unix_time, address payable recipient) public{
		require(msg.sender==database_owner);
		emit OfferCreateEvent(num_offers, houseid,day,month,year, price, source, escrow_unix_time);
		offer_src[num_offers] = source;
		offer_house[num_offers] = houseid;
		offer_escrow_end_unix_time[num_offers] = escrow_unix_time;
		offer_recipient[num_offers] = recipient;
		offer_acceptor[num_offers] = address payable(0);
		num_offers+=1;
	}
	
	function cancelOffer(uint64 offer_id) public{
	    require(offer_id<num_offers);
	    require(offer_recipient[offer_id]==msg.sender);
	    require(offer_acceptor[offer_id]==address payable(0));
	    offer_recipient[offer_id] = address payable(0);
	    emit OfferCancelEvent(offer_id);
	}
	
	function buyHouse(uint64 offer_id) public {
	    require(offer_id<num_offers);
	    require(balanceOf(msg.sender)>=offer_price[offer_id]);
	    require(offer_acceptor[offer_id]!=address payable(0));
	    require(offer_recipient[offer_id]!=address payable(0));
	    balances[msg.sender]-=offer_price[offer_id];
	    
	    offer_acceptor[offer_id] = msg.sender;
	    
	    offer_escrow_end_unix_time[offer_id] = block.timestamp + offer_escrow_unix_time[offer_id];
	    
	    emit event OfferAcceptEvent(offer_id);
	}
	
	function cancelBuy(uint64 offer_id) public {
	    require(offer_id<num_offers);
	    require(offer_acceptor[offer_id]==msg.sender);
	    require(offer_escrow_end_unix_time[offer_id]<block.timestamp);
	    
	    offer_acceptor[offer_id] = address payable(0);
	    balances[msg.sender]-=offer_price[offer_id];
	    
	    emit event BuyCancelEvent(offer_id);
	}
	
	function claimPayout(uint64 offer_id) public {
	    require(offer_id<num_offers);
	    require(offer_escrow_end_unix_time[offer_id]>block.timestamp);
	    require(offer_recipient[offer_id]==msg.sender);
	    
	    balances[msg.sender]+=offer_price[offer_id];
	    
	    event OwnershipTransfer(offer_id);
	    
	}
	
	function addHouse(string memory adr, uint32 sqft, uint8 bedroom,uint8 bathroom,uint8 h_type, uint16 yr_built, uint32 lotsize, uint64 parcel, uint32 zip) public{
		require(msg.sender==database_owner);
		require(bytes(adr).length<128);
		addresses[num_houses] = adr;
		sqfts[num_houses]=sqft;
		bedrooms[num_houses]=bedroom;
		bathrooms[num_houses]=bathroom;
		house_type[num_houses]=h_type;
		year_built[num_houses]=yr_built;
		lot_size[num_houses] = lotsize;
		parcel_num[num_houses] = parcel;
		zipcode[num_houses] = zip;
		num_houses++;
	}
	function resetHouseParams(uint64 num_house, uint32 sqft, uint8 bedroom,uint8 bathroom,uint8 h_type, uint16 yr_built, uint32 lotsize, uint64 parcel, uint32 zip) public{
		require(msg.sender==database_owner);
		sqfts[num_house]=sqft;
		bedrooms[num_house]=bedroom;
		bathrooms[num_house]=bathroom;
		house_type[num_house]=h_type;
		year_built[num_house]=yr_built;
		lot_size[num_house] = lotsize;
		parcel_num[num_house] = parcel;
		zipcode[num_house] = zip;
	}
	
	event DonationEvent();
	
	function ()external payable{
		emit DonationEvent();
	}
	
	function getFee() public view returns (uint fee){
		uint a = oracle_adr.balance;
		if(a>min_balance)return min_fee;
		return (min_balance-a)/fee_div;
	}
	
	function getSellReturn(uint amount) public view returns (uint value){	// ether for selling amount tokens
		uint a = getFee();
		if(a>(amount*base_price/10000))return 0; // if the fee outweighs the return
		return (amount*base_price/10000) - a;
	}
	
	function getBuyCost(uint amount) public view returns (uint cost){		// ether cost for buying amount tokens
	    return (amount*base_price/10000) + getFee();
	}
	
	event SellEvent(uint tokens);
	event BuyEvent(uint tokens);
	
	function buy(uint tokens)public payable{
	    uint cost = getBuyCost(tokens);
		require(msg.value>=cost);
		require(tokens*base_price>=tokens, "overflow detected (base cost)");
		require(balances[address(this)]>=tokens);
		
		require(cost>getFee(), "overflow detected (cost)");
		require(balances[msg.sender]+tokens > balances[msg.sender], "overflow detected (balance)");
		
		balances[address(this)]-=tokens;
		balances[msg.sender]+=tokens;
		    
		lastTradedPrice = base_price;
		    
		emit Transfer(address(this), msg.sender, tokens);
		emit BuyEvent(tokens);
		
		msg.sender.transfer(msg.value-cost);
		
		if(oracle_adr.balance<min_balance)
		    oracle_adr.transfer(getFee());
		else
		    owner.transfer(getFee()/2);
	}
	
	function sell(uint tokens)public{
	    uint result = getSellReturn(tokens);
	    require(balances[msg.sender]>=tokens);
		require(address(this).balance>result);
		
		require(balances[msg.sender]-tokens < balances[msg.sender], "overflow detected");
		
		balances[address(this)]+=tokens;
		balances[msg.sender]-=tokens;
		    
		lastTradedPrice = base_price;
		    
		emit Transfer(msg.sender, address(this), tokens);
		emit SellEvent(tokens);
		
		if(oracle_adr.balance<min_balance)
		    oracle_adr.transfer(getFee());
		else
		    owner.transfer(getFee()/2);
		msg.sender.transfer(result);
	}
	
	function get_tradable() public view returns (uint tradable){
		return balances[address(this)];
	}
	
	function setPrice(uint newPrice) public{
		require(msg.sender==oracle_adr);
		base_price = newPrice;
	}
	
	function setFeeParams(uint new_min_fee, uint new_fee_div, uint new_min_bal) public{
	    require(msg.sender==owner);
	    require(new_fee_div>0);
	    min_fee = new_min_fee;
	    min_balance = new_min_bal;
	    fee_div = new_fee_div;
	}
	
	
	/* ================================================================================================
	 *
	 *  Below are functions created for administration and contract management, or extreme cases.
	 *
	 * ================================================================================================ */
	
	bool public oracle_change_ready = false;
	
	function allowOracleChange() public {
	    require(msg.sender==oracle_adr);
	    oracle_change_ready = true;
	}
	
	function setOracleAddress(address payable adr) public {
	    require(msg.sender==owner);
	    require(oracle_change_ready);
	    oracle_adr = adr;
	    oracle_change_ready=false;
	}
	
	function mint(uint amt) public{
		require(msg.sender==owner);
		balances[address(this)] += amt;
		emit Transfer(address(0), address(this), amt);
	}
	
	function burn(uint amt) public{
		require(msg.sender==owner);
		require(balances[owner]>=amt);
		balances[owner]-=amt;
		emit Transfer(owner, address(0), amt);
	}
	
	function destroy() public {
		require(msg.sender==owner);
		selfdestruct(oracle_adr);
	}
}
