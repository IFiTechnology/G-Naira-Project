// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GNaira is ERC20, Ownable {

    address public governor;
    address[] public multisigOwners;
    uint256 public multisigThreshold;
    mapping(address => bool) public isMultisigOwner;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public _isHolder;
    address[] public _holders;
    

    constructor(uint initialSupply) ERC20("G-Naira", "gNGN") {
        governor = msg.sender; //Make deployer account Governor
        multisigOwners.push(governor); //Add governor to multisig owners
        isMultisigOwner[governor] = true; //Set governer true in isMultisigOwner
        multisigThreshold; //Set minimum multisig signers to 1
        _mint(msg.sender, initialSupply * 10 ** decimals()); // minting the initial supply 
    }

 //MODIFIER FUNCTIONS

    //@modifier onlyGovernor
    // this modifier restricts transactions to the GOVERNOR
    modifier onlyGovernor() {
        require(msg.sender == owner(), "GNaira: Only the Governor can call this Function!!");
        _;
    }

    //@modifier checkAddressAndAdd: Push address to holders array

    modifier checkAddressAndAdd(address _addressToCheck) {
        bool exists = false;
        for (uint i = 0; i < _holders.length; i++) {
            if (_holders[i] == _addressToCheck) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _holders.push(_addressToCheck);
        }
        _;
    }

    //@modifier onlyMultisig 
    // Ensure minimum signers requirement are met
    modifier onlyMultisig() {
        uint256 count = 0;
        for (uint256 i = 0; i < multisigOwners.length; i++) {
            if (isMultisigOwner[multisigOwners[i]]) {
                count++;
            }
        }
        require(count >= multisigThreshold, "The Threshold requirement not met");
        _;
    }

    //@modifier isHolder
    //  Prevent adding duplicate 
    modifier isHolder(address _account) {
         require(!_isHolder[_account], "GNaira: this user is already a holder");
         _;
    }


    //Below is the MINT, BURN, BLACKLIST, WHITELIST and TRANSFER function 

  function blackList(address _user) public onlyGovernor {
      require(!isBlacklisted[_user], "User Has Been Blacklisted");
      isBlacklisted[_user] = true;

  }


    function whiteList(address _user) public onlyGovernor {
      require(isBlacklisted[_user], "User Has Been Whitelisted");
      isBlacklisted[_user] = false;

  }

  
    function mint(address account, uint amount) external onlyMultisig{
      _mint(account, amount);
    }

    function burn(uint amount) external onlyMultisig {
        _burn(msg.sender, amount);
    
      }


    // overiding the _beforeTokenTranfer to prevent any blacklisted account from carryout any transaction
    // blacklisted accounts can't transfer nor recieve untill they are whitelisted 
     function _beforeTokenTransfer(
       address from, 
       address to, 
       uint256 amount) 
       internal virtual override {
          require(!isBlacklisted[from], "Transaction Declined: This User has been Blaklisted!!");
          require(!isBlacklisted[to], "Transaction Declined: This Reciever has been Blacklisted");
          super._beforeTokenTransfer(from, to, amount);
       }
   
  
    // Below are the MULTISIG functions

    //@function Add multisig owner
    //only the Governor can access this function
    function addMultisigOwner(address _newOwner) public onlyGovernor {
        require(!isMultisigOwner[_newOwner], "GNaira: Address is already a multisig owner");
        multisigOwners.push(_newOwner);
        isMultisigOwner[_newOwner] = true;
    }


    //@function Remove multisig owner
    //only the Governor can access this function 
    function removeMultisigOwner(address _multisigOwner) public onlyGovernor {
        require(isMultisigOwner[_multisigOwner], "GNaira: Address is not a multisig owner");
        require(_multisigOwner != governor, "GNaira: Cannot remove the governor from the multisig group");
        isMultisigOwner[_multisigOwner] = false;

        for (uint256 i = 0; i < multisigOwners.length - 1; i++) {
            if (multisigOwners[i] == _multisigOwner) {
                multisigOwners[i] = multisigOwners[multisigOwners.length - 1];
                break;
            }
        }

        multisigOwners.pop();
    }

    //@function addHolder: 
    // Adds holder to holders array
    //only the Governor can access this function
    function addHolder(address _account) isHolder(_account) private {
         _holders.push(_account);
    }

   
}