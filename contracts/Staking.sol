// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Withdraw__TransferFailed();
error ClaimReward__TransferFailed();
error MoreThanZero__MustBeMoreThanZero();

contract Staking {

    // the ONLY token accepted by our contract for staking
    IERC20 public s_stakingToken;
    // the token give as a reward for staking
    IERC20 public s_rewardToken;

    // how much a user has staked
    mapping(address => uint256) public s_balances;
    // how much each user has been paid
    mapping(address => uint256) public s_userRewardPerTokenPaid;
    // how much rewards each user has availabe to claim
    mapping(address => uint256) public s_rewards;

    uint256 public constant REWARD_RATE = 100;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerStakedToken;
    uint256 public s_lastUpdateTime;

    modifier updateReward(address account) {
        // what is the reward per token stored?
        // s_rewardPerStakedToken = totalEmit / totalSupply
        s_rewardPerStakedToken = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerStakedToken;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert MoreThanZero__MustBeMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }

    // only allows one specific ERC20 token
    // require that the token given is the accepted token
    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount){
        s_balances[msg.sender] += amount;
        s_totalSupply += amount;
        // emit event

        //transferFrom is from IERC20
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
         // require(success, "Failed to stake");
         if(!success) {
             revert Staking__TransferFailed();
         }
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount){
        s_balances[msg.sender] -= amount;
        s_totalSupply -= amount;
        // transfer is from IERC20
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if(!success) {
            revert Withdraw__TransferFailed();
        }
    }

    function rewardPerToken() public view returns(uint256){
        if(s_totalSupply == 0) {
            return s_rewardPerStakedToken;
        } 
        return s_rewardPerStakedToken + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18/ s_totalSupply ));
    }

    function earned(address account) public view returns(uint256) {
        uint256 currentBalance = s_balances[account];
        // how much have they been paid already?
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 totalEarned = ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;
        return totalEarned;
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 rewards = s_rewards[msg.sender];
        bool success = s_rewardToken.transfer(msg.sender, rewards);
        if(!success) {
            revert ClaimReward__TransferFailed();
        }
    }

    function getStaked(address account) public view returns (uint256) {
        return s_balances[account];
    }
}