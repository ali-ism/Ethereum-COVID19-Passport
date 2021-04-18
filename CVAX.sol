pragma solidity ^0.5.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.4.0/contracts/math/SafeMath.sol";

contract CVAX {
    
    string public constant name = "CVAXToken";
    string public constant symbol = "CVAX";
    uint8 public constant decimals = 0;
    
    mapping(address => uint256) balance;
    uint256 private _totalSupply;
    
    address private _contract_owner;
    mapping(address => bool) pharm_company;
    mapping(address => bool) vax_center;
    
    mapping(address => uint256) dose_history;
    
    using SafeMath for uint256;
    
    constructor() public {
        _contract_owner = msg.sender;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balance[account];
    }
    
    //Check if holder of valid COVID-19 passport
    function isPassport(address account) public view returns (bool) {
        require(!vax_center[account]);
        require(!pharm_company[account]);
        return balance[account] == 2;
    }
    
    //Contract owner registers a new pharmaceutical company to supply vaccines
    function registerPharmCompany(address company) public returns (bool) {
        require(msg.sender == _contract_owner);
        require(company != _contract_owner);
        require(!vax_center[company]);
        pharm_company[company] = true;
        return true;
    }
    
    //Contract owner registers a new vaccination center
    function registerVaxCenter(address center) public returns (bool) {
        require(msg.sender == _contract_owner);
        require(center != _contract_owner);
        require(!pharm_company[center]);
        vax_center[center] = true;
        return true;
    }
    
    //Pharmaceutical company supplies tokens to a vaccination center
    function supplyVax(uint256 amount, address center) public returns (bool) {
        require(pharm_company[msg.sender]);
        require(vax_center[center]);
        require(amount > 0);
        balance[center] = balance[center].add(amount);
        _totalSupply = _totalSupply.add(amount);
        return true;
    }
    
    //Vaccination center gives a patient a shot
    function administerDose(address patient) public returns (bool) {
        require(vax_center[msg.sender]);
        require(balance[msg.sender] > 0);
        require(!vax_center[patient]);
        require(!pharm_company[patient]);
        require(balance[patient] < 2);
        if (balance[patient] == 1 && block.timestamp - dose_history[patient] < 1602933557) {
            return false;
        }
        dose_history[patient] = block.timestamp;
        balance[patient] = balance[patient].add(1);
        balance[msg.sender] = balance[msg.sender].sub(1);
        _totalSupply = _totalSupply.sub(1);
        return true;
    }
}