# Deployments

## Unichain Sepolia - Full v4 Integration

Status: deployed and smoke-tested.

This deployment uses CREATE2 address mining so `RiskShieldHook` has the correct Uniswap v4 hook permission bits.

```text
Network: Unichain Sepolia
Chain ID: 1301
PoolManager: 0x00B036B58a818B1BC34d502D3fE730Db729e62AC
MockUSDC: 0xb0cD9Ec340036f47F4655d9BBfE1E172E3209A06
MockRiskAsset: 0x72290EB00a06c4a5582c64e8E336F6e4D242bE87
RiskShieldVault: 0xAE2fbD03F210206774BD2A43Bc96823a18022a5f
HookDeployer: 0xDDD40c0B487e5a2E7f95E5A80e1871917Cb4165e
RiskShieldHook: 0xd9E54DB85EC7BbBFbFE1d47fae90b941aA4aC7C0
RiskShieldPoolRouter: 0x11fB0B3C8355fF826a3BC9316ea5B0A46E2FF0C0
Deployer/Admin: 0xD3a758f7818f20830b7ECB4CC89146f541Ea41C7
Hook permission mask: 0x07c0
Pool ID: 0xf7ab8f4eeb4e9ae1a8bf02a06f9d65aeeabefe42d29c38473c354eaaad1d4ba5
Broadcast file: broadcast/DeployV4RiskShield.s.sol/1301/run-latest.json
```

Pool key:

```text
currency0: 0x72290EB00a06c4a5582c64e8E336F6e4D242bE87
currency1: 0xb0cD9Ec340036f47F4655d9BBfE1E172E3209A06
fee: 8388608
tickSpacing: 60
hooks: 0xd9E54DB85EC7BbBFbFE1d47fae90b941aA4aC7C0
```

Deployment transaction hashes:

```text
MockUSDC deploy:          0xa64d7a217b03f45e85b4e8fcbdd5cf85f01ffe98168204a6d6507d69cc412f3e
MockRiskAsset deploy:     0x3cee56e06d6119da72b1c623abfbb2c977e303529d562750b7a3af319baac4fa
RiskShieldVault deploy:   0x433ed77ed54ee5feb110a1835cae8d08ce3392f1f4222f46aabd87a96485e147
HookDeployer deploy:      0xb85555f64602d007bac040b1431cad3007a728d24f0789898b4504d5ae2be994
RiskShieldHook deploy:    0x5e83e386783cd2291453a9fe65ab0378d85b26f1effa3fb3c94b7dc3fac09f48
Vault setHook:            0xdd879f09dfcf939a8b664bec1f61f787b4ad67b354b3befd08a4c808dd8296ab
Router deploy:            0x438b6f03455aed8439dee156afff42b1b67a6d1a0e6193db7b2efad2deb947a6
Pool initialize:          0x90d7a79f533dbd3fa2dcd67a96b138ba1db81362a93126050d57782c25c240f7
```

Smoke test status: passed.

The smoke script minted mock tokens, approved the router, added real v4 liquidity through `PoolManager.modifyLiquidity`, executed a real v4 swap through `PoolManager.swap`, and funded the RiskShield premium reserve through the router path.

```text
Mint MockUSDC:            0x6822978201ec4f328e12de1df84be73181d8ba012be7f6f7ad8a9e44bdc2cc73
Mint MockRiskAsset:       0xb8a518afed10b1802a03de609346ba308fe6cb7c60293e86c9620cdeb0250a0f
Approve MockUSDC:         0xcf570a3f8e7e419cc6d0dd69bbfb09a02efc87a3581746afc47d9ad9a4d1b78c
Approve MockRiskAsset:    0xecafbad324b495e507ded8f2512bb873d00aa72e167b4b659978c94537a38e9a
Add v4 liquidity:         0xf22f7745e916a1c7cea87a34c6a1ffa85cf392dd50582b9ad6c1889e97f8f5e3
Swap and fund premium:    0x44f09bf669f493c1bf53f65df1829be20e3de172896bc5b79534fd4f77c449bd
```

Onchain readback after smoke:

```text
RiskShieldVault.reserveAvailable(poolId): 10000000
RiskShieldVault.nextPositionId(): 2
RiskShieldHook.lastPremiumBps(poolId): 17
Senior position 1 owner: 0xD3a758f7818f20830b7ECB4CC89146f541Ea41C7
Senior position 1 closed: false
```

`MockUSDC` uses 6 decimals, so `10000000` equals `10 MockUSDC`.

Important MVP note: the v4 swap and dynamic fee callback are real. The current router funds the insurance reserve alongside the swap. It does not directly siphon PoolManager LP fees into the vault yet.

## Unichain Sepolia - Earlier Vault/Hook Logic Deployment

Status: deployed and verified.

Deployment command:

```bash
forge script script/DeployRiskShield.s.sol:DeployRiskShield --rpc-url unichain_sepolia --broadcast
```

To deploy and verify in one command, add `--verify`:

```bash
forge script script/DeployRiskShield.s.sol:DeployRiskShield --rpc-url unichain_sepolia --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

Uniswap's Unichain deployment guide recommends verification during deployment because the compile parameters are known at deployment time.

Deployment order:

1. `MockUSDC`
2. `MockRiskAsset`
3. `RiskShieldVault`
4. `RiskShieldHook`
5. `RiskShieldVault.setHook(hook)`
6. `RiskShieldVault.transferAdmin(deployer)`

Unichain Sepolia v4 PoolManager:

```text
0x00b036b58a818b1bc34d502d3fe730db729e62ac
```

## Address Log

```text
Network: Unichain Sepolia
Chain ID: 1301
MockUSDC: 0xf8c3682A1C3cCE91FF3709Cc4907681c98dC0Ce4
MockRiskAsset: 0x02DbDbf1A81f49c420E811660947a0a0d8eEA229
RiskShieldVault: 0x6e588Be8931BC10dB885940400EF45DFc0390f7f
RiskShieldHook: 0x12BFab9b8b6020133B7732537e5eD106Bf33e876
Deployer/Admin: 0xD3a758f7818f20830b7ECB4CC89146f541Ea41C7
Broadcast file: broadcast/DeployRiskShield.s.sol/1301/run-latest.json
Verified: Yes
```

Explorer links:

- MockUSDC: https://sepolia.uniscan.xyz/address/0xf8c3682a1c3cce91ff3709cc4907681c98dc0ce4
- MockRiskAsset: https://sepolia.uniscan.xyz/address/0x02dbdbf1a81f49c420e811660947a0a0d8eea229
- RiskShieldVault: https://sepolia.uniscan.xyz/address/0x6e588be8931bc10db885940400ef45dfc0390f7f
- RiskShieldHook: https://sepolia.uniscan.xyz/address/0x12bfab9b8b6020133b7732537e5ed106bf33e876

Onchain sanity checks:

```text
RiskShieldVault.admin(): 0xD3a758f7818f20830b7ECB4CC89146f541Ea41C7
RiskShieldVault.hook(): 0x12BFab9b8b6020133B7732537e5eD106Bf33e876
RiskShieldHook.poolManager(): 0x00B036B58a818B1BC34d502D3fE730Db729e62AC
```

## Real Testnet Smoke Test

Smoke test status: passed.

Actions executed on Unichain Sepolia:

1. Minted `100 MockUSDC` to deployer.
2. Approved `RiskShieldVault` to spend `100 MockUSDC`.
3. Deposited `100 MockUSDC` as junior insurance capital.
4. Read vault state back onchain.

Transaction hashes:

```text
Mint MockUSDC:      0x3b5e7b5ccd647ba1b119bc5331d5957690238e4ecf4a9c636a5bdded5cdfa274
Approve Vault:      0xf652bbc58bafde268bae93f6167f33641f214c910be0acf95e9bcda9b8047454
Deposit Junior:     0xeacdc0508fc5058d3132cad17e98f87754a60062c6c299cc039fcf8b3496a56d
```

Readback:

```text
reserveAvailable(poolId): 100000000
juniorBalanceOf(poolId, deployer): 100000000
MockUSDC.balanceOf(vault): 100000000
```

`MockUSDC` uses 6 decimals, so `100000000` equals `100 MockUSDC`.

## Post-Deployment Verification

If deployment succeeds but verification was not included, verify each contract after broadcast.

MockUSDC constructor has no args:

```bash
forge verify-contract --chain-id 1301 --watch --etherscan-api-key $ETHERSCAN_API_KEY <MOCK_USDC_ADDRESS> src/mocks/MockUSDC.sol:MockUSDC
```

MockRiskAsset constructor has no args:

```bash
forge verify-contract --chain-id 1301 --watch --etherscan-api-key $ETHERSCAN_API_KEY <MOCK_RISK_ASSET_ADDRESS> src/mocks/MockRiskAsset.sol:MockRiskAsset
```

RiskShieldVault constructor arg is the `MockUSDC` address:

```bash
forge verify-contract --chain-id 1301 --watch --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" <MOCK_USDC_ADDRESS> <DEPLOY_SCRIPT_ADDRESS_OR_INITIAL_ADMIN>) \
  <VAULT_ADDRESS> src/RiskShieldVault.sol:RiskShieldVault
```

RiskShieldHook constructor args are the Unichain Sepolia PoolManager and deployed vault address:

```bash
forge verify-contract --chain-id 1301 --watch --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" 0x00b036b58a818b1bc34d502d3fe730db729e62ac <VAULT_ADDRESS>) \
  <HOOK_ADDRESS> src/RiskShieldHook.sol:RiskShieldHook
```

For the earlier vault deployment, verification may be easier from the broadcast artifact because the initial admin during construction is the deploy script contract address, and admin is transferred to the deployer after construction.

## Hook Address Note

Uniswap v4 production hooks must be deployed at an address whose lower bits match the enabled hook permissions. RiskShield currently enables:

- `afterAddLiquidity`
- `beforeRemoveLiquidity`
- `afterRemoveLiquidity`
- `beforeSwap`
- `afterSwap`

For Progress Update 2, `DeployV4RiskShield.s.sol` mines the hook address with CREATE2, validates the `0x07c0` permission mask, deploys the hook at the mined address, and initializes the v4 pool through the Unichain Sepolia PoolManager.
