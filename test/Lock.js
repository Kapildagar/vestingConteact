const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const {ethers} = require("hardhat");

describe("vesting contract", function () {
  
  let token;
  let vestingContract;

  let deployer;
  let teamWallet;

  const amounToLock =  ethers.parseEther();

  before(async()=>{
    [deployer,teamWallet] = await ethers.getSigner();
  })


  this.beforeEach(async()=>{
    const tokenFactory = await ethers.getContractFactory("MockERC20");
    token = await tokenFactory.deploy();

    const vestingFactory = await ethers.getContractFactory("Lock");

    vestingContract = await vestingFactory.deploy(token.address);
    ethers.provider.send()
  })
});
