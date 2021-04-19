pragma solidity ^0.5.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.4.0/contracts/math/SafeMath.sol";

contract ERC20CVAX {
    
    string public constant name = "CVAXToken";
    string public constant symbol = "CVAX";
    uint8 public constant decimals = 0;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    mapping(address => uint256) balances;
    uint256 private _totalSupply;
    
    address private _contract_owner;
    
    mapping(address => bool) public pharm_company;
    mapping(address => bool) public vax_center;
    mapping(address => bool) public patient;
    mapping(address => uint256) public dose_history;
    
    using SafeMath for uint256;
    
    constructor() public {
        _totalSupply = 0;
        _contract_owner = msg.sender;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        require(!pharm_company[_owner]);
        return balances[_owner];
    }
    
    //Contract owner registers a new pharmaceutical company to supply vaccines
    function registerPharmCompany(address company) public returns (bool) {
        require(msg.sender == _contract_owner);
        require(company != address(0));
        require(company != _contract_owner);
        require(!vax_center[company]);
        require(!patient[company]);
        pharm_company[company] = true;
        return true;
    }
    
    //Contract owner registers a new vaccination center
    function registerVaxCenter(address center) public returns (bool) {
        require(msg.sender == _contract_owner);
        require(center != address(0));
        require(center != _contract_owner);
        require(!pharm_company[center]);
        require(!patient[center]);
        vax_center[center] = true;
        return true;
    }
    
    //Three types of transfers: company to vax center, vax center to vax center, vax center to patient
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_to != address(0));
        //pharm company (faucet) supplying doses to a vax center
        if (pharm_company[msg.sender]) {
            require(vax_center[_to]);
            _totalSupply = _totalSupply.add(_value);
        }
        //vax center transferring doses to another vax center
        else if (vax_center[msg.sender] && vax_center[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
        }
        //vax center administering dose to a patient
        else if (vax_center[msg.sender]) {
            require(!pharm_company[_to]);
            require(balances[_to] < 2);
            require(_value == 1);
            //if not first dose check if 1 month has passed since first dose
            if (balances[_to] == 1 && block.timestamp - dose_history[_to] < 2592000) {
                revert();
            }
            patient[_to] = true;
            dose_history[_to] = block.timestamp;
            balances[msg.sender] = balances[msg.sender].sub(_value);
        }
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    //Check if holder of valid COVID-19 passport
    function isValidPassport(address _owner) public view returns (bool) {
        require(patient[_owner]);
        return balances[_owner] == 2;
    }
}
