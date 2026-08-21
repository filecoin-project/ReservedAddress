# Reserved Addresses

`ReservedAddress` is an immutable CREATE2 factory for claiming an address before choosing the code deployed there.
Ownership of a claimed address is represented by an ERC-721 token whose token ID is the address.

The factory is fixed at `0x000000000000c57CF0A1f923d44527e703F1ad70`.
Deploying the same factory there on multiple EVM chains makes a salt resolve to the same reserved address on each chain.

The fixed factory address depends on replaying the same signed legacy transaction on each chain.
The legacy transaction hash must match on every chain.
Verify it and the deployed runtime code before relying on the factory.

## How it works

The reserved address depends only on the factory, a salt, and the factory's 32-byte deployment [trampoline](https://en.wikipedia.org/wiki/Trampoline_(computing)):

```solidity
address constant DEPLOYER = 0x000000000000c57CF0A1f923d44527e703F1ad70;
bytes32 constant INIT_CODE_HASH =
    0xbcbbfadcc59d9dc57408c9c0b8c471bde38115ed725ac4bbe1308d01651d5d99;

address reserved = address(uint160(uint256(keccak256(abi.encodePacked(
    bytes1(0xff),
    DEPLOYER,
    salt,
    INIT_CODE_HASH
)))));
```

The reservation does not commit to the eventual contract code.
The ERC-721 owner supplies that code when deploying.

### Reserve and reveal

1. Compute or mine a salt and its reserved address.
2. Call `reserve(reserved)` from the account which will initially own it.
3. Call `reveal(reserved, salt)` from the same account.

`reserve` starts a 24-hour exclusive period.
After that period anyone may call `dispute` to replace an unrevealed reservation with their own 24-hour reservation.
The original holder may still reveal after expiry until a successful dispute replaces it.

Both the target address and reservation transaction are public.
A competing transaction can reserve the target first and delay the intended owner.
The salt also becomes public when it is revealed.
Reserve a cross-chain address on every intended public chain before revealing it on any of them; otherwise another account can claim the same address on a chain where it remains unreserved.

### Deploy

The `initCode` argument to `deploy(reserved, initCode)` is an address whose runtime bytecode is the complete EVM creation code for the target contract, including encoded constructor arguments.
Publish this code container on the target chain before calling `deploy`.
The code-container address may differ between chains because it is not part of the reserved-address calculation.

Deployment proceeds as follows:

1. The factory creates the fixed 32-byte trampoline at `reserved` with CREATE2.
2. The trampoline asks the factory for the `initCode` address.
3. It delegate-calls the creation code in the new contract's context.
4. The returned bytes become the new contract's runtime code.

The constructor therefore observes `address(this) == reserved` and `msg.sender == DEPLOYER`.
Storage writes occur at `reserved`.

Only the ERC-721 owner may deploy.
A successful deployment clears the stored salt, so the address can be deployed only once.

### Control after deployment

The ERC-721 owner may call `call(deployed, callData)`.
The target sees the factory as `msg.sender`, so this can hand off ownership when a constructor made the factory owner:

```solidity
deployer.call(
    deployed,
    abi.encodeCall(Ownable.transferOwnership, (finalOwner))
);
```

Transferring the ERC-721 transfers the authority to use the factory's `deploy` and `call` methods.
It does not directly alter authorisation stored by the deployed contract.

## Security and operational properties

- The reserved address commits to the salt and trampoline, not the eventual contract code.
  Verify the creation code separately before deployment.
- Treat the ERC-721 and all token approvals as deployment and factory-call authority.
  Hold production reservations in the intended governance account.
- The factory has no administrator or recovery path.
  An accidental token transfer can permanently lose control.
- Empty-calldata callbacks reject value.
  `deploy` forwards only that call's value, so an existing factory balance cannot alter constructor value or block a non-payable constructor.
  Any funds otherwise forced into the factory remain stranded.
- Constructor code must tolerate the factory as `msg.sender`.
  Prefer explicit constructor ownership parameters where possible.

## Development

```sh
# Clone the repository
git clone --recurse-submodules git@github.com:filecoin-project/ReservedAddress.git
cd ReservedAddress

# Build and run the tests
make test
```

### Makefile

Makefile recipes facilitate incremental builds.

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
lib/evm/bin/evm -w test/dio/Approve.json
```

### Foundry Tests

Foundry tests live in `test/` and have a `.t.sol` suffix.

```sh
# List all tests
find test -name '*.t.sol'

# Run a test individually
forge test --match-path test/ERC721/SafeTransfer.t.sol
```
