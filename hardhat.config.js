require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");
require('@nomiclabs/hardhat-etherscan');
require('dotenv').config();


module.exports = {
  solidity: "0.8.7",
  namedAccounts: {
    deployer: {
      default: 0
    }
  }
};
