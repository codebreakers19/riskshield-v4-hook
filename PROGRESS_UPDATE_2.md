# UHI9 Progress Update 2

Project ID: `HK-UHI9-0946`

Project Name: RiskShield - Tranche-Based IL Insurance Hook

## Brief Progress Update

RiskShield is on track for Progress Update 2. The MVP hook and vault are implemented with senior protected LP accounting, junior first-loss reserve deposits, dynamic premium fee calculation, premium reserve accounting, coverage caps, and `onlyPoolManager` callback protection.

Since Progress Update 1, I expanded the test suite around adverse price paths and demo-critical flows. The local Foundry suite verifies senior IL compensation, reserve-capped coverage, max coverage caps, no-loss exits, premium behavior, hook callback access control, senior position double-close protection, deployment wiring, and full v4 integration against a real local PoolManager.

The project now has a full Unichain Sepolia v4 integration deployment. The hook was deployed through CREATE2 at a v4-valid permission address, the pool was initialized through the real Unichain Sepolia PoolManager, liquidity was added through `PoolManager.modifyLiquidity`, and a real swap was executed through `PoolManager.swap`. The smoke flow funded the RiskShield reserve through the router path and recorded the dynamic premium state onchain.

## Form Answers

- Is your hook demoable? **Yes**
- Do you have a working hook contract deployed locally? **Yes**
- Test Coverage Level: **D - Good coverage, most paths tested (50-80%)**
- Do you have a deployment script? **Yes**
- Have you deployed to a testnet? **Yes**
- Can your hook be routed by the Uniswap? **No**
- Have you tested integration with a frontend? **Yes**

## Testnet Addresses

```text
Network: Unichain Sepolia
Chain ID: 1301
MockUSDC: 0xb0cD9Ec340036f47F4655d9BBfE1E172E3209A06
MockRiskAsset: 0x72290EB00a06c4a5582c64e8E336F6e4D242bE87
RiskShieldVault: 0xAE2fbD03F210206774BD2A43Bc96823a18022a5f
RiskShieldHook: 0xd9E54DB85EC7BbBFbFE1d47fae90b941aA4aC7C0
RiskShieldPoolRouter: 0x11fB0B3C8355fF826a3BC9316ea5B0A46E2FF0C0
Pool ID: 0xf7ab8f4eeb4e9ae1a8bf02a06f9d65aeeabefe42d29c38473c354eaaad1d4ba5
```

## Current Verification Result

```text
forge test -vv: 28 tests passed, 0 failed, 0 skipped
forge test --gas-report: 28 tests passed, 0 failed, 0 skipped
npm run compile: compiled 32 source units successfully
npm run build: Vite production build succeeded
```

## Honest Demo Scope

The v4 pool integration is real: mined hook address, pool initialization, v4 liquidity modification, v4 swap, and hook callback execution. The reserve funding is currently routed through `RiskShieldPoolRouter` alongside the swap rather than directly redirecting PoolManager LP fees into the vault. That is the remaining production-hardening step after Progress Update 2.
