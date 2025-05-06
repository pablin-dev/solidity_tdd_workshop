# TDD Solidity Workshop

Date: 2025-01-20

## Context

Test-Driven Development (TDD) is a software development process that relies on the repetitive cycle of writing automated tests before writing the actual code. In the context of Solidity, TDD is particularly useful for ensuring the reliability and security of smart contracts.

TDD offers several advantages when developing smart contracts in Solidity:

* **Improved code quality**: By writing tests before writing the code, developers can ensure that their code is testable and meets the required functionality.
* **Reduced bugs**: TDD helps catch bugs and errors early in the development process, reducing the likelihood of downstream problems.
* **Faster development**: Although it may seem counterintuitive, TDD can actually speed up the development process by reducing the time spent on debugging and testing.
* **Better design**: TDD promotes a design-driven approach to development, where the tests inform the design of the code.

In the context of this workshop, we will be using TDD to develop a NFT staking contract. By following the TDD process, we will ensure that our contract is reliable, secure, and meets the required functionality.

## Hands on

As your first assignment, we encourage you to do a `NFT staking contract` for the campaign `NFT fun`.

In a normal day in development department.

A `Product manager` work with the target audience via `questions` or `polls` and `voting governance` to select most relevant needs.

Then with the `CEO` establish a course of decisions and funding.

With the help of `Analyst, Technical leader and a UX` give life to a project on `docs`.

This project is taken by the `Project Manager` and the `Technical Leader` and create all the `Tasks` need it and a `Plan` to try to fulfill.

The day has come to `Earn` campaign with `NFT staking contract`.

Your `Technical leader` create and initialize a project with all the tech need it.

It assigns you some issues according to a `Plan`.

**Are you ready for what it takes the challenge?**

## Tasks

Your first `Task` is to read all the specification design and learn about the project scope and boundaries.

* Understand how the [architecture](docs/specifications/architecture.md) works.
* Understand what is expected for you to do with [lock-unlock](docs/specifications/staking.md) and [exchange](docs/specifications/exchange.md) according to the `user stories`.

### User Story 001

Read the [001 NFT Lock Staking](docs/stories/0001-nft-stake-lock.md) User Story.

Challenge:

* Try to use TDD on this first assignment.
* Use [erc721](https://docs.openzeppelin.com/contracts/5.x/erc721).
* Implement the User Story 001 smart contract.
* Keep your code commented [natspec-format](https://docs.soliditylang.org/en/latest/natspec-format.html).
* Test Coverage must be 85% higher.

### User Story 002

Read the [002 NFT Unlock Staking](docs/stories/0002-nft-stake-unlock.md) User Story.
Challenge:

* Do the same tasks as `User Story 0001`
* Deploy and run the tests over local blockchain.

### User Story 003

Read the [003 NFT recover Staking](docs/stories/0003-nft-unstaking.md) User Story.
Challenge:

* Do the same tasks as `User Story 0001`
* Deploy and run the tests over testnet blockchain.

### User Story 004

Read the [004 User Points Consumeed](docs/stories/0004-exchange-points-erc20.md) User Story.
Challenge:

* Do the same tasks as `User Story 0001`.
* Create a PR and wait for reviews!!!

## Commands that will help you

```shell
forge test --match-contract ComplicatedContractTest --match-test test_Deposit -vvvv
clear && forge coverage --report lcov && genhtml -o report --branch-coverage lcov.info --ignore-errors inconsistent --ignore-errors category
```

```shell
forge coverage --no-match-path 'test/invariant/**/*.sol' --report lcov
lcov --extract lcov.info --rc branch_coverage=1 --rc derive_function_end_line=0 -o lcov.info 'src/*' 
genhtml lcov.info --rc branch_coverage=1 --rc derive_function_end_line=0 -o coverage

clear && forge coverage --report lcov && genhtml -o report --branch-coverage lcov.info --ignore-errors inconsistent --ignore-errors category

source .env
forge script script/Deploy.s.sol:Deploy --sig 'run()' --fork-url $CHAIN_RPC --broadcast
```

```shell
cast tx 0x... --rpc-url $CHAIN_RPC
cast call 0x... "isWhitelisted(address)" 0x4f1D03A710859AA7D400AC389D132C21Dee64305 --rpc-url $CHAIN_RPC
```
