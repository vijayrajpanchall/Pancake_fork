# Decentralized Exchange Task (PancakeswapV2 Fork)

## Table of Content

- [Decentralized Exchange Task (PancakeswapV2 Fork)](#decentralized-exchange-task-pancakeswapv2-fork)
  - [Table of Content](#table-of-content)
  - [Project Description](#project-description)
  - [For achiving this task I have done the following:](#for-achiving-this-task-i-have-done-the-following)
  - [Technologies Used](#technologies-used)
  - [A typical top-level directory layout](#a-typical-top-level-directory-layout)
  - [Install and Run](#install-and-run)


## Project Description

This project is a clone of Pancakeswap that replicates the swap functionality of the original platform. which includes functions to initiate, confirm, and cancel token swaps while ensuring slippage tolerance. 

## For achiving this task I have done the following:

1. PancakeRouter.sol
    * Removes all the previous swap functions.
    * Added InitiateSwap, ConfirmSwap, and CancelSwap functions.
    * Added necessary events and mappings to track the swaps.

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
