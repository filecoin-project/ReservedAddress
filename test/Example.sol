// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

contract Example {
    address public owner;
    uint256 public myNumber;
    constructor() {
        owner = msg.sender;
    }

    function setMyNumber(uint256 number) external {
        require(msg.sender == owner);
        myNumber = number;
    }
    
    function pay(address payable recipient) external payable {
        recipient.transfer(msg.value);
    }
}
