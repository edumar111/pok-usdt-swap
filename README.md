## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>

forge script script/DeployPok.s.sol   --broadcast --verify
forge script script/DeployUsdt.s.sol   --broadcast --verify

forge script script/DeploySwap.s.sol   --broadcast --verify
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

POK Contract Address: 0x647c3888f9251Ad075e0b2419Af69c79f47896E8
USDT Contract Address: 0x7626d6883754a3b6870eED9D33BA4a2F2d36dE44
SWAP Contract Address: 0x06D7d7833708bF82cc6c7a05cA38e9bDceCb4224
