pragma solidity >=0.5.0 <0.9.0;

contract Auction{
    address payable public owner;
    uint public starttime;
    uint public endtime;

    enum auction_State{started,running,end,cancelled}
    auction_State public auctionState;
    uint public HighestBindingBid;
    uint public highest_payable_bid;
    uint public bid_inc;
    address payable public  highestBidder;
    mapping(address => uint)public bids;   

    constructor(){
        owner= payable(msg.sender);
        auctionState=auction_State.running;
        starttime=block.number;
        endtime= starttime+240;
        bid_inc= 1 ether;
    }


    modifier notOwner(){
        require(msg.sender!= owner);
        _;
    }

    modifier Owner(){
        require(msg.sender== owner);
        _;
    }

    modifier Started(){
        require(block.number>starttime);
        _;
    }
    
    modifier beforeEnding(){
        require(block.number<endtime);
        _;
    }
    function emergency()public Owner{
        auctionState=auction_State.cancelled;
    }
    function min(uint a, uint b) pure private returns (uint){
        if(a<b){
            return a;
        }
        else
        return b;
    }

    function bid() payable public notOwner Started beforeEnding{
        require(auctionState==auction_State.running);
        require(msg.value>=1 ether);
        uint currentBid = bids[msg.sender]+msg.value;
        require(currentBid>highest_payable_bid);
        bids[msg.sender]=currentBid;
        if(currentBid<bids[highestBidder]){
            highest_payable_bid=min(currentBid+bid_inc,bids[highestBidder]);

        }
        else{
            highest_payable_bid=min(currentBid,bids[highestBidder]+bid_inc);
            highestBidder=payable(msg.sender);
        }
}

function finalizeAuction()public{
    require(auctionState==auction_State.cancelled || block.number> endtime);
    require(msg.sender==owner || bids[msg.sender]>0);
    address payable collector;
    uint value;
    if(auctionState==auction_State.cancelled){
        collector=payable(msg.sender);
        value=bids[msg.sender];
    }
    else{
        if(msg.sender==owner)
        {
            collector=owner;
            value=highest_payable_bid;
        }
        else{
            if(msg.sender==highestBidder)
            {
                collector=highestBidder;
                value=bids[highestBidder]-highest_payable_bid;
            }
            else{
                collector=payable(msg.sender);
                value=bids[msg.sender];
            }
        }
    }
    bids[msg.sender]=0;
    collector.transfer(value);
}
}