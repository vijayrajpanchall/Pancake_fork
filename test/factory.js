const { expect } = require("chai");
const { ethers, hre } = require("hardhat");

describe("Factory", function () {
    let factory;
    let accounts;
    beforeEach(async function () {
        accounts = await ethers.getSigners();
        const Factory = await ethers.getContractFactory("PancakeFactory");
        factory = await Factory.deploy(accounts[0].address);
        await factory.deployed();
    });

    it("Should create pair", async function () {
        const tokenA = await ethers.getContractFactory("ERC20");
        const tokenB = await ethers.getContractFactory("DeflatingERC20");
        const totalSupply = ethers.utils.parseEther("10000");

        const tokenAInstance = await tokenA.deploy(totalSupply);
        const tokenBInstance = await tokenB.deploy(totalSupply);

        await tokenAInstance.deployed();
        await tokenBInstance.deployed();

        await factory.createPair(tokenAInstance.address, tokenBInstance.address);
        const pairLength = await factory.allPairsLength();
        expect(pairLength.toString()).to.equal("1");
    });        

    it("Should set setFeeTo", async function () {
        await factory.setFeeTo(accounts[1].address);
        expect(await factory.feeTo()).to.equal(accounts[1].address);
    });
});