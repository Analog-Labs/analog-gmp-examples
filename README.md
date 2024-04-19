## Analog's cross-chain dApp examples

**This repo provides the code for several example of dApps utilizing Analog's General Message Passing protocol.**

## Dependencies

This project uses **Forge** Ethereum testing framework (like Truffle, Hardhat and DappTools).
Install instructions: https://book.getfoundry.sh/

## Examples

- [Simple Counter](./examples/teleport-tokens/README.md): Increment a counter in a contract deployed at `Chain A` by sending a message from `Chain B`. 
- [Teleport Tokens](./examples/teleport-tokens/README.md): Teleport ERC20 tokens from `Chain A` to `Chain B`. 

## Starting a New Project
To start a new project with Foundry, use forge init
```sh
forge init hello_gmp
```
This creates a new directory hello_gmp from the default Foundry template. This also initializes a new git repository.

Install analog-gmp dependencies.
```sh
cd hello_gmp
forge install Analog-Labs/analog-gmp
```

All setup! now just need to import gmp dependencies from `@analog-gmp`:
```solidity
import {IGmpReceiver} from "@analog-gmp/interfaces/IGmpReceiver.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
```

### Writing Tests
You can easily write cross-chain unit tests using analog's testing tools at `@analog-gmp-testing`.
```solidity
import {GmpTestTools} from "@analog-gmp-testing/GmpTestTools.sol";

// Deploy gateway contracts and create forks for all supported networks
GmpTestTools.setup();

// Set `account` balance in all networks
GmpTestTools.deal(address(account), 100 ether);

// Switch to Sepolia network
GmpTestTools.switchNetwork(5);

// Switch to Shibuya network and set `account` as `msg.sender` and `tx.origin`
GmpTestTools.switchNetwork(7, address(account));

// Relay all pending GMP messages.
GmpTestTools.relayMessages();
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test -vvv
```

### Format

```shell
$ forge fmt
```

## License

Analog's Contracts is released under the [MIT License](LICENSE).
