pragma solidity ^0.5.0;
import './StandardToken.sol'; 

contract WasteWaterRecyclingCertificates is StandardToken {
    string public constant symbol = "WRC";
    string public constant name = "WasteWaterRecyclingCertificates";
    uint256 public constant decimals = 18;
    uint256 public constant tokenPrice = 10**17;
    // uint256 internal totalSupply_ = 3000000 * 10**18;
    uint256 public unused_supply = 0;
    uint256 public usable_supply = 0;
    uint256 public spread_supply = 0;
    uint256 public reward = 500000 * 10**decimals;
    uint256 public timeOfLastHalf = now;
    uint public timeOfLastIncrement = now;
    // mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint)) private __allowances;
    mapping (address => uint) public __percentReuse;
    address payable public owner;
    uint private constant RegulatorTarget=35 ;
    // event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, uint256 value);
    uint256 public shareholdersBalance;
    uint public totalShareholders;
    mapping (address => bool) registeredShareholders;
    mapping (uint => address) shareholders;
   
    /* At the time of contract deployment first function to be called is Owned()*/
   
    
    // function Owned() public returns (address) {
        
    //     return (owner);
    // }

    
    modifier onlyOwner {
        require(msg.sender == owner) ;
        _;
    }
    constructor() payable public {
        owner = msg.sender;
        timeOfLastHalf = now;  
        totalSupply_ = 3000000 * 10**18;
        balances[msg.sender] = totalSupply_;
    }
    
  
    function updateSupplyforRegulator() internal returns (uint256) {

      if (now - timeOfLastHalf >= 2100000 minutes) {
        reward /= 2;
        timeOfLastHalf = now;
      }

      if (now - timeOfLastIncrement >= 150 seconds) {
        uint256 increaseAmount = ((now -timeOfLastIncrement) / 150 seconds) * reward;
        usable_supply += increaseAmount;
        unused_supply += increaseAmount;
        timeOfLastIncrement = now;
      }


      spread_supply = usable_supply - unused_supply;
      
      return spread_supply;
    }

      
    function balanceOf(address _addr) public view returns (uint balance) {
        return balances[_addr];
    }

     /*  minting the WRC currency  */   
     function IssueWRC() public payable {
        uint256 _value;
         _value = (msg.value)/ tokenPrice; //conversion
         _value = _value * 10 ** decimals;
        // require(balances[msg.sender] + _value >= balances[msg.sender]); // Check for overflows
        
        updateSupplyforRegulator();

        require(unused_supply - _value <= unused_supply);
        unused_supply -= _value; // Remove from unused supply
        balances[msg.sender] += _value; // Add the same to the recipient
        totalSupply_ += _value;
        updateSupplyforRegulator();
        emit Mint(msg.sender, _value);

       if (msg.sender != owner) {
            shareholdersBalance += _value;
       }
        
     }
     
  
    function withdraw(address payable _to, uint _amount) public payable returns (bool) {

        //user can withdraw his tokens only
        require(msg.sender == _to);

         uint256 amountToWithdraw = _amount * 10**18;
        // Balance given in WRC

        require(balances[_to] >= amountToWithdraw);
        require(balances[_to] - amountToWithdraw <= balances[_to]);

        // Balance checked in WRC, then converted into Wei
        balances[_to] -= amountToWithdraw;

        // Added back to supply in WRC
        unused_supply +=amountToWithdraw;
        // Converted into Wei
        amountToWithdraw =msg.value* 1000000;

        uint ethValue = _amount * tokenPrice;

        _to.send(ethValue); 
        // Transfered in Wei
        // transferFrom(msg.sender,_to,amountToWithdraw);
        
        updateSupplyforRegulator();
        
       if (msg.sender != owner) {
            shareholdersBalance -= amountToWithdraw;
       }
        

        return true;
    }


   
    function totalSupply() public view returns (uint _totalSupply) {
        _totalSupply = totalSupply_ / 10**18;
        
        
    }

    function transfer(address _to,uint  _value) public returns(bool) {

    }

    function transferWithPercentReuse(address _to, uint256 _value , uint _percentReuse ) public  {
        
        require(balances[_to] + _value >= balances[_to]); // Check for overflows
        balances[msg.sender] -= _value;                    // Subtract from the sender
        balances[_to] += _value;                           // Add the same to the recipient

        updateSupplyforRegulator();
         /* Adding to shareholders count if tokens spent from owner to others */
        if (msg.sender == owner && _to != owner) {
            shareholdersBalance += _value;
        }
        /* Remove from shareholders count if tokens spent from holder to owner */
        if (msg.sender != owner && _to == owner) {
            shareholdersBalance -= _value;
        }

        if (owner == _to) {
            // sender is owner
        } else {
            CalculatingTotalShareholders(_to,_percentReuse);
        }


        /* Notify anyone listening that the transfer took place */
        emit Transfer(msg.sender, _to, _value);

        
    }
    /**
     * only for the already registered participant organizations
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_from == msg.sender);
        require(balances[_from] > 0);
        if (__allowances[_from][msg.sender] > 0 &&
            _value > 0 &&
            __allowances[_from][msg.sender] >= _value && 
            balances[_from] >= _value) {
            balances[_from] -= _value;
            balances[_to] += _value;
            
            __allowances[_from][msg.sender] -= _value;
            
            updateSupplyforRegulator();
       
            /* Notify anyone listening that the transfer took place */
            emit Transfer(_from, _to, _value);
            return true;
        
        }
        return false;
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        __allowances[msg.sender][_spender] = _value;
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return __allowances[_owner][_spender];
   }
   
 

    function CalculatingTotalShareholders( address _shareholder ,uint _percentReuse) internal returns (bool) {
      
        if (registeredShareholders[_shareholder] == true) {

        } else { 
            totalShareholders += 1;
            shareholders[totalShareholders] = _shareholder;
            __percentReuse[shareholders[totalShareholders]]=_percentReuse;     
            registeredShareholders[_shareholder] = true;
            return true;
        }
        return false;
    }
    
    /**
     * stock variant it varies according to the no of overachieved organisations
     * overachieved organisations : _percentReuse>RegulatorTarget
     */
    uint256 public stockprice;
    function payDividends() public payable onlyOwner returns(uint) {
        if (totalShareholders > 0) {
                        
            for (uint i = 1; i <= totalShareholders; i++) {
            uint _percentReuse=__percentReuse[shareholders[i]];                  
            uint256 currentBalance = balances[shareholders[i]];
                if(_percentReuse>RegulatorTarget &&currentBalance>0 ) {
                    stockprice =  (tokenPrice*currentBalance/10**18) / shareholdersBalance;
                    transferWithPercentReuse(shareholders[i],stockprice,_percentReuse);
                }
            }
                return stockprice;
            
        }
    }
 
}
