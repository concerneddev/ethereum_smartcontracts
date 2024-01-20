// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

contract CrowdFunding {
    using PriceConverter for uint256;

    // Funder details
    struct Funder {
        address addr;
        uint256 amount;
    }

    // Campaign details
    struct CampaignDetails {
        uint256 minimumAmount;
        uint256 targetAmount;
        bool started;
        bool ended;
        address owner;
    }
    
    CampaignDetails public campaign;

    // Funders
    Funder[] public funders;

    constructor() {
        campaign.owner = msg.sender;
    }

    modifier ownerOnly {
        require(msg.sender == campaign.owner, "Not owner!");
        _;
    }

    // Setting the Minimum and Target
    function setMinimumTarget(uint256 _minimumAmount, uint256 _targetAmount) public ownerOnly {
        require(!campaign.started, "Campaign already started!");
        require(_minimumAmount >= 0, "Invalid Minimum Amount!");
        require(_targetAmount > campaign.minimumAmount, "Invalid Target Amount!");
        campaign.minimumAmount = _minimumAmount * 1e10;
        
        campaign.targetAmount = _targetAmount * 1e10;

    }

    // Getting the Minimum and Target Amount
    function getMinimum() view public returns (uint256) {
        return campaign.minimumAmount / 1e10;
    }

    function getTarget() view public returns (uint256) {
        return campaign.targetAmount / 1e10;
    }

    // Start the campaign
    function startCampaign() public ownerOnly {
        campaign.started = true;
    }

    // Get Amount generated
    function getAmountGenerated() view public returns(uint256) {
        uint256 amountGenerated = address(this).balance;
        return amountGenerated;
    }
    
    // Funding the campaign
    function fund() public payable {
        require(campaign.started, "Campaign Not Started Yet!");
        require(msg.sender != campaign.owner, "Owner cannot donate!");
        require(msg.value.getConversionRate() >= campaign.minimumAmount, "Didnt send enough!");
        require(msg.value.getConversionRate() <= campaign.targetAmount, "Amount too big");
        
        if(address(this).balance <= campaign.targetAmount){
            // Adding the funder to the funders array1
            funders.push(Funder(msg.sender, msg.value));
        }else{
            campaign.ended = true;
        }
    }

    // Funders
    // Total funders
    function getTotalFunders() view public returns(uint256){
        return funders.length;
    }

    // Latest funder
    function getLatestFunder() view public returns(address, uint256){
        require(funders.length > 0, "Zero funders!");
        Funder storage latestFunder = funders[funders.length-1];
        return (latestFunder.addr, latestFunder.amount);
    }

    // Withdrawing the funds
    function withdraw() public ownerOnly{
        require(campaign.ended == true, "Target not reached");
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }
}
