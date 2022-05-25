pragma solidity >=0.5.6;

contract IERC20{

    function totalSupply() public view returns (uint); 
    function balanceOf(address account) public view returns (uint);
    function transfer(address recipient, uint amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function approve(address spender, uint amount) public returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20{

    uint public supply;
    address public owner;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;

    string public name = "CryptosToken";
    string public symbol = "ERC20";
    uint8 public decimals = 18;

    constructor() public{
        supply=100000;
        owner= msg.sender;
        balances[owner]=supply;
    }

    function totalSupply() public view returns (uint){
        return supply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowances[tokenOwner][spender];
    } 

    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount
    ) public returns (bool) {
        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

}

contract ICO is ERC20{

    address public admin;
    address payable public deposit;
    uint public tokenPrice = 0.001 ether;
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800;
    uint public coinTradeStart = saleEnd + 604800;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.01 ether;

    enum State{Start, Running, End, Stopped}
    State public icoState;

    modifier onlyAdmin{
        require(msg.sender==admin);
        _;
    }

    event Invest(address investor,uint value,uint tokens);
    
    constructor(address payable _deposit) public{
        deposit =_deposit;
        admin = msg.sender;
        icoState = State.Start;
    }

    function stopped() public onlyAdmin{
        icoState=State.Stopped;
    }
    
    function running() public onlyAdmin{
        icoState=State.Running;
    }

    function end() public onlyAdmin{
        icoState=State.End;
    }

    function invest() payable public returns(bool){
        
        require(icoState==State.Running); 
        require(msg.value >= minInvestment && msg.value<=maxInvestment);
        uint tokens=msg.value/tokenPrice;
        require(raisedAmount+msg.value<=hardCap);
        raisedAmount+=msg.value;
        balances[msg.sender]+=tokens;
        balances[owner]-=tokens;
        deposit.transfer(msg.value);
        emit Invest(msg.sender,msg.value,tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transfer(to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transferFrom(from, to, tokens);
        return true;
    }
    
    function burn() public returns(bool){
        require(icoState == State.End);
        balances[owner] = 0;
	return true;

    }
}

