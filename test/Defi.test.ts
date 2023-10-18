import { ethers, waffle } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("UniswapLikeExchange", () => {
  let tokenA: Contract;
  let tokenB: Contract;
  let exchange: Contract;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();

    const TokenA = await ethers.getContractFactory("MyToken");
    const TokenB = await ethers.getContractFactory("MyToken2");
    const Exchange = await ethers.getContractFactory("UniswapLikeExchange");

    tokenA = await TokenA.deploy();
    tokenB = await TokenB.deploy();
    await tokenA.deployed();
    await tokenB.deployed();

    exchange = await Exchange.deploy(tokenA.address, tokenB.address, 1000); // Assuming 1000 as the initial k value
    await exchange.deployed();
  });

  it("should add liquidity and swap tokens", async () => {
    const initialBalanceA = await tokenA.balanceOf(owner.address);
    const initialBalanceB = await tokenB.balanceOf(owner.address);

    // Add liquidity
    const liquidityAmountA = ethers.utils.parseEther("100"); // Amount of TokenA for liquidity
    const liquidityAmountB = ethers.utils.parseEther("200"); // Amount of TokenB for liquidity
    await tokenA.connect(owner).approve(exchange.address, liquidityAmountA);
    await tokenB.connect(owner).approve(exchange.address, liquidityAmountB);
    await exchange
      .connect(owner)
      .addLiquidity(liquidityAmountA, liquidityAmountB);

    const finalBalanceA = await tokenA.balanceOf(owner.address);
    const finalBalanceB = await tokenB.balanceOf(owner.address);

    expect(finalBalanceA).to.equal(initialBalanceA.sub(liquidityAmountA));
    expect(finalBalanceB).to.equal(initialBalanceB.sub(liquidityAmountB));

    // Swap tokens
    const swapAmountA = ethers.utils.parseEther("10"); // Amount of TokenA to swap
    await tokenA.connect(owner).approve(exchange.address, swapAmountA);
    await exchange.connect(owner).swap(swapAmountA);

    const newBalanceA = await tokenA.balanceOf(owner.address);
    const newBalanceB = await tokenB.balanceOf(owner.address);

    expect(newBalanceA).to.equal(finalBalanceA.add(swapAmountA));
    expect(newBalanceB).to.not.equal(finalBalanceB); // TokenB balance should change after the swap
  });
});
