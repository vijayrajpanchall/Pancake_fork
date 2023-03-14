# Decentralized Exchange Task (UniswapV2 Fork)

## Table of Content

- [Decentralized Exchange Task (UniswapV2 Fork)](#decentralized-exchange-task-uniswapv2-fork)
  - [Table of Content](#table-of-content)
  - [Project Description](#project-description)
  - [For achiving this task I have done the following:](#for-achiving-this-task-i-have-done-the-following)
  - [Technologies Used](#technologies-used)
  - [A typical top-level directory layout](#a-typical-top-level-directory-layout)
  - [Install and Run](#install-and-run)
  - [Test](#test)


## Project Description

This project is fork of uniswapV2 in with addition fee of 4% is taken from each trade, with 2% coming from the incoming token and 2% coming from the outgoing token. For example, if a user swaps $100 worth of BUSD for USDC, they will receive 96 dollars worth of USDC, and the exchange's reward wallet will receive $2 worth of BUSD and $2 worth of USDC.

## For achiving this task I have done the following:

1. UniswapV2Router02.sol
    * Modified all the swap functions to add a fee of 2% for outgoing token. (98% of the outgoing token will be sent to the recipient and 2% will be sent to the treasury wallet.)
    * Fee will be sent to the treasury wallet.
2. UniswapV2Pair.sol
    * Modified the _swap function to add a fee of 2% for incoming token.
    * Fee will be sent to the treasury wallet.

3. UniswapV2Factory.sol
    * Added a treasury wallet where the fees are sent to.
    * Added a function to set the treasury wallet.
    * Added a function to update treasury wallet.

4. UniswapV2Library.sol
    *  Modified the getAmountsOut function to remove liquidity fee from all transactions.
    * Modified the getAmountsIn function to remove liquidity fee from all transactions.
    * Modified the getAmountIn and getAmountOut functions to remove liquidity fee from all transactions.

## Technologies Used

- Soldity
- Openzepplein
- Hardhat

## A typical top-level directory layout

    .
    ├── Contracts               # Contract files (alternatively `dist`)
    ├── Scripts                 # Script files (alternatively `deploy`)
    ├── test                    # Automated tests (alternatively `spec` or `tests`)
    ├── LICENSE
    └── README.md

## Install and Run

To run this project, you must have the following installed:

1.  [nodejs](https://nodejs.org/en/)
2.  [npm](https://github.com/nvm-sh/nvm)

- Run `npm install` to install dependencies

```bash
$ npm install
```

- Run `npx hardhat compile` to compile all contracts.

```bash
$ npx hardhat compile
```

## Test

For a unit testing smart contract using the command line.

```
$ npx hardhat test
```

Expecting `router-test.js` result.

```bash

  Router
    ✔ Should deploy (1341ms)
    ✔ Should add liquidity (2150ms)
    ✔ Should add liquidity using ether (534ms)
    ✔ Should remove liquidity (301ms)
    ✔ Should remove liquidity in ETH pair (376ms)
    ✔ should return correct amount from getAmountsOut without fee
    ✔ should return correct amount from getAmountsIn 
without fee
    ✔ Should return correct value from getAmountsOut 
without fee (120ms)
    ✔ Should return correct value from getAmountsIn without fee (115ms)
    ✔ Should swap swapExactTokensForTokens (266ms)
    ✔ Should transfer 2% of incoming token to treasury in swapExactTokensForTokens (306ms)
    ✔ Should transfer 2% of outgoing token to treasury in swapExactTokensForTokens (338ms)
    ✔ Should swap swapTokensForExactTokens (328ms)
    ✔ Should transfer 2% of outgoing token to treasury in swapTokensForExactTokens (341ms)
    ✔ Should transfer 2% of incoming token to treasury in swapTokensForExactTokens (324ms)
    ✔ Should swap swapTokensForExactTokens in path[3] (779ms)
    ✔ Should transfer 2% of incoming token to treasury in swapTokensForExactTokens in path[3] (431ms)     
    ✔ Should transfer 2% of outgoing token to treasury in swapTokensForExactTokens in path[3] (440ms)     
    ✔ Should swap swapExactETHForTokens (440ms)
    ✔ Should transfer 2% of outgoing token to treasury in swapExactETHForTokens (273ms)
    ✔ Should transfer 2% of incoming token to treasury in swapExactETHForTokens (285ms)
    ✔ Should transfer 2% of incoming token to treasury in swapTokensForExactETH (299ms)
    ✔ Should transfer 2% of outgoing token to treasury in swapTokensForExactETH (298ms)
    ✔ Should transfer 2% of outgoing token to treasury in swapExactTokensForETH (297ms)
    ✔ Should transfer 2% of incoming token to treasury in swapExactTokensForETH (291ms)
    ✔ Should transfer 2% of incoming token to treasury in swapETHForExactTokens (300ms)
    ✔ Should transfer 2% of outgoing token to treasury in swapETHForExactTokens (297ms)


  27 passing (11s)
```



```
After testing if you want to deploy the contract using the command line.


$ npx hardhat node
# Open another Terminal
$ npx hardhat run scripts/deploy.js

# result in npx hardhat node Terminal
web3_clientVersion
eth_chainId
eth_accounts
eth_chainId
eth_estimateGas
eth_gasPrice
eth_sendTransaction
  Contract deployment: <UnrecognizedContract>
  Contract address:    0x5fb...aa3
  Transaction:         0x4d8...945
  From:                0xf39...266
  Value:               0 ETH
  Gas used:            323170 of 323170
  Block #1:            0xee6...85d

eth_chainId
eth_getTransactionByHash
eth_blockNumber
eth_chainId (2)
eth_getTransactionReceipt

# result in npx hardhat run Terminal
Deployer:  0xf3...266
Core contract[Factory] deployed to: 0xD5...d0b
Periphery[RouterV2] contract deployed to: 0x3C...1e9

```