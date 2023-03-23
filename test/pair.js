const { expect } = require("chai");
const { ethers, hre } = require("hardhat");

describe("Pancake Pair", function () {
    let pair;
    let accounts;
    let factory;
    let tokenA;
    let tokenB;
    let totalSupply;

    beforeEach(async function () {
        accounts = await ethers.getSigners();
        const Pair = await ethers.getContractFactory("PancakePair");
        const Factory = await ethers.getContractFactory("PancakeFactory");
        pair = await Pair.deploy();
        factory = await Factory.deploy(accounts[0].address);
        await pair.deployed();
        await factory.deployed();

        const TokenA = await ethers.getContractFactory("ERC20");
        const TokenB = await ethers.getContractFactory("DeflatingERC20");
        totalSupply = ethers.utils.parseEther("10000");

        tokenA = await TokenA.deploy(totalSupply);
        tokenB = await TokenB.deploy(totalSupply);

        await tokenA.deployed();
        await tokenB.deployed();
    });

    it("Should create pair", async function () {
        await factory.createPair(tokenA.address, tokenB.address);
        const pairLength = await factory.allPairsLength();
        expect(pairLength.toString()).to.equal("1");
    });

    it('should have a token0 and token1 address', async () => {
        const token0 = await pair.token0();
        const token1 = await pair.token1();

        expect(token0).to.not.be.empty;
        expect(token1).to.not.be.empty;
    });

    it('should have a factory address', async () => {
        const factoryAddress = await pair.factory();
        expect(factoryAddress).to.not.be.empty;
    });

    it('should have a kLast value', async () => {
        const kLast = await pair.kLast();
        expect(kLast).to.not.be.empty;
    });


    it('should have a MINIMUM_LIQUIDITY value', async () => {
        const MINIMUM_LIQUIDITY = await pair.MINIMUM_LIQUIDITY();
        expect(MINIMUM_LIQUIDITY.toString()).to.equal("1000");
    });

    it('should have a getReserves function', async () => {
        const reserves = await pair.getReserves();
        expect(reserves).to.not.be.empty;
    });

});   