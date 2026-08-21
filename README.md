# Reserved Addresses

This factory provides a way to claim addresses for future deployments.
These addresses are ERC-721 NFTs.

## Usage

1. Mine a salt for your CREATE2 address
2. `reserve` the address
3. `reveal` the salt for address within 24 hours to become the owner
4. Deploy the initcode for your contract anywhere
5. Use `deploy` to run the initcode, initializing your contract

### Mining a CREATE2 address

TODO

### `reserve` the address

TODO

### `reveal` the salt

TODO

### Deploy the initcode

TODO

### `deploy` the contract

TODO

### Limitations

The `msg.sender` of your `constructor` is the Deployer factory.
The contract's owner can use `call` to invoke the contract from the Deployer.
For example, if your constructor sets `msg.sender` to be the owner, then you can use `call` to `transferOwnership`.

## Development

```sh
# Clone the repository
git clone --recurse-submodules git@github.com:filecoin-project/ReservedAddress.git
cd ReservedAddress

# Build, and run the tests
make test
```

### Makefile

Makefile recipies facilitate incremental builds.

```sh
# build
make

# clean
make clean

# test
make test

# update ABI
make abi
```

### Assembly Tests

Assembly tests live in `test/dio/`.
```sh
# Run a test individually
lib/evm/bin/evm -u test/dio/Approve.json`
```

### Foundry Tests

Foundry tests live in `test/` and have a `.t.sol` suffix

```sh
# List all tests
find test -name *.t.sol

# Run a test individually
forge test test/ERC721/SafeTransfer.t.sol
```
