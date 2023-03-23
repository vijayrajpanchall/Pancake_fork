const { expect } = require("chai");
const { ethers, hre } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");


describe("Router", function () {

    async function deployTokenFixture() {
        const accounts = await ethers.getSigners();

        const Router = await ethers.getContractFactory("PancakeRouter");
        const Factory = await ethers.getContractFactory("PancakeFactory");
        const WETH = await ethers.getContractFactory("WBNB");
        const tokenA = await ethers.getContractFactory("ERC20");
        const tokenB = await ethers.getContractFactory("DeflatingERC20");
        const tokenC = await ethers.getContractFactory("DeflatingERC20");

        const totalSupply = ethers.utils.parseEther("1000000");

        const tokenAInstance = await tokenA.deploy(totalSupply);
        const tokenBInstance = await tokenB.deploy(totalSupply);
        const tokenCInstance = await tokenC.deploy(totalSupply);

        await tokenAInstance.deployed();
        await tokenBInstance.deployed();
        await tokenCInstance.deployed();

        const weth = await WETH.deploy();
        const factory = await Factory.deploy(accounts[0].address);
        const router = await Router.deploy(factory.address, weth.address);

        await weth.deployed();
        await factory.deployed();
        await router.deployed();

        await tokenAInstance.approve(router.address, ethers.utils.parseEther("1000000"));
        await tokenBInstance.approve(router.address, ethers.utils.parseEther("1000000"));
        await tokenCInstance.approve(router.address, ethers.utils.parseEther("1000000"));

        // Fixtures can return anything you consider useful for your tests
        return { tokenAInstance, tokenBInstance, tokenCInstance, router, factory, weth, accounts };
    }

    it("Should deploy", async () => {
        const { router, factory, weth } = await loadFixture(deployTokenFixture);
        expect(await router.factory()).to.equal(factory.address);
        expect(await router.WETH()).to.equal(weth.address);
    });

    it("User can initiate Swap", async () => {
        const { tokenAInstance, tokenBInstance, router, accounts } = await loadFixture(deployTokenFixture);
        const user = accounts[1].address;

        await router.addLiquidity(
            tokenAInstance.address, 
            tokenBInstance.address, 
            ethers.utils.parseEther("1000"), 
            ethers.utils.parseEther("1000"), 
            0, 
            0, 
            accounts[0].address, 
            ethers.constants.MaxUint256
        );

        await router.initiateSwap(
            tokenAInstance.address,
            tokenBInstance.address,
            ethers.utils.parseEther("10"),
            1,
        );

        const events = await router.queryFilter(router.filters.SwapInitiated());
        const event = events[0];
        const swapId = event.args.swapId;

        // const swapData = await router.swaps(swapId);
        // console.log(swapData[0]);

        expect(swapId).not.equal(0);
    });

    it("User can cancel Swap", async () => {
        const { tokenAInstance, tokenBInstance, router, accounts } = await loadFixture(deployTokenFixture);
        const user = accounts[1].address;

        await router.addLiquidity(
            tokenAInstance.address, 
            tokenBInstance.address, 
            ethers.utils.parseEther("1000"), 
            ethers.utils.parseEther("1000"), 
            0, 
            0, 
            accounts[0].address, 
            ethers.constants.MaxUint256
        );

        await router.initiateSwap(
            tokenAInstance.address,
            tokenBInstance.address,
            ethers.utils.parseEther("10"),
            1,
        );

        const events = await router.queryFilter(router.filters.SwapInitiated());
        const event = events[0];
        const swapId = event.args.swapId;

        await router.cancelSwap(swapId);

        const swapData = await router.swaps(swapId);
        expect(swapData[6]).to.equal(false);
    });

    it("User can confirm Swap", async () => {
        const { tokenAInstance, tokenBInstance, router, accounts } = await loadFixture(deployTokenFixture);
        const user = accounts[1].address;

        await router.addLiquidity(
            tokenAInstance.address, 
            tokenBInstance.address, 
            ethers.utils.parseEther("1000"), 
            ethers.utils.parseEther("1000"), 
            0, 
            0, 
            accounts[0].address, 
            ethers.constants.MaxUint256
        );

        await router.initiateSwap(
            tokenAInstance.address,
            tokenBInstance.address,
            ethers.utils.parseEther("10"),
            1,
        );

        const events = await router.queryFilter(router.filters.SwapInitiated());
        const event = events[0];
        const swapId = event.args.swapId;

        await router.confirmSwap(swapId);

        const swapData = await router.swaps(swapId);
        const isSwapConfirmed = swapData[7];
        expect(isSwapConfirmed).to.equal(true);
    });
});