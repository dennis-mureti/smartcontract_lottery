// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzepplin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable{
    address payable[] public players; // to keep track of all players
    address payable public recentWinner;
    uint256 public randomness; // to keep track of the random number
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUSDPriceFeed; // to helpin conversion
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    // since we have a type LOTTERY_STATE we can create a variable LOTTERY_STATE as well
    LOTTERY_STATE public lottery_state;
    uint256 public fee; // since the fee can change, we can have it as an input parameter as well in our constructor
    bytes32 public keyHash; // will e used to uniquely identify the chainlink VRF node
    // the above states are actually represented by numbers e.g OPEN->0 CLOSED->1 and CALCULATING_WINNER->2
    // 0
    // 1
    // 2

    // constructor to help in setting up the minimum fee // we inherit the VRFConsumerBase contrucor in our own constrauctor
    constructor (
        address _priceFeedAddress, 
        address _vrfCoordinator, 
        address _link, 
        uint256 _fee, 
        bytes32 _keyHash
        ) public VRFConsumerBase (_vrfCoordinator, _link) { //parametize by passing address of priceFeed as a constructor parameter->address _pricefeedaddress
        usdEntryFee = 50 * (10**18); // for unit of mesure we do times 10 raised to the 18
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED; // now to set our lottery_state to being closed
        fee = _fee; // underscore to mean global
        keyHash  = _keyHash;
    }

    function enter() public payable { // payable since it requires tobe paid for
       // 50$ minimum
       require(lottery_state == LOTTERY_STATE.OPEN); // to show that one can only enter when someone has started this lottery
       require(msg.value >= getEntranceFee(), "Not enough ETH"); // after getting entrance fee now we do this
       players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) { // since we returning a number we makeit public view returns (uint256)
        // since we are going to use conversion we usethe chainlink pricefeed. u can use chainlink/get_the_latest_price
        (, int price, , ,) = ethUSDPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // to convert from int256 to uint256 and convert to 18 decimals
        // to set the price at $50 and pricefeed of $2000/ETH
        // 50/2000 but solidity can't do this
        // we do 50 * 10000 / 2000
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice;
        return costToEnter;
    }

    // can only be called by the admin
    function startLottery() public onlyOwner{
        require(lottery_state == LOTTERY_STATE.CLOSED, "can't start a new lottery yet");
        lottery_state = LOTTERY_STATE.OPEN; // when we start new lottery
    }

    // we are now going to choose our random winner from this function // ownly the woner can end the lotter
    function endLottery() public onlyOwner {
        // incorrect format for generating random numbers in brownie
        // uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % players.length
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER; // to change the state of our lottery and whilethis is happenig no one can do anything else
        bytes32 requestId = requestRandomness(keyHash, fee); // request and receive architechture, to request data from chainlink oracle and return to fullfilRandomnes
    }

    // is internal bcoz only the VRFCordinator can call and return this function and we ovveride the original declaration of the function
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't there yet."); // to check that we are in the right state

        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length; // to helpin getting the winner where we want to be left withe the winner alone
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance); // now after getting winner we give the entire balance to the winner
        // reset the lottery to start from scratch
        players = new address payable[] (0);
        lottery_state  = LOTTERY_STATE.CLOSED;
        randomness = _randomness;  // to keep track of random number
    }
}