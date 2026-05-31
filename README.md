# RiskShield - Tranche-Based IL Insurance Hook

RiskShield makes Uniswap v4 LPing insurable by splitting liquidity into senior protected LP capital and junior first-loss insurance capital.

Project ID: `HK-UHI9-0946`

UHI9 Theme: Impermanent Loss and Yield Systems

## Problem

Passive LPs still underwrite impermanent loss and loss-versus-rebalancing without a clear way to price or transfer that risk. This keeps conservative capital out of volatile Uniswap pools and makes LP yield hard to forecast.

## Solution

RiskShield introduces an insurance layer around a Uniswap v4 pool:

- Senior LPs provide protected liquidity and receive lower-risk yield.
- Junior insurers provide first-loss reserve capital and earn premium yield.
- Traders pay a dynamic impermanent-loss protection premium when swaps are larger or more volatile.
- Premiums build the insurance reserve.
- When senior LPs exit, the vault compares their LP exit value against a hold benchmark and pays covered loss from the reserve.

The MVP keeps the mechanism self-contained. It avoids perps, lending, options, and external oracle dependencies so the hook is easy to reason about and demo.

## Why Uniswap v4 Hooks

Uniswap v4 hooks can run around pool lifecycle events. RiskShield uses this to:

- Observe liquidity additions and removals.
- Signal higher LP fees before risky swaps.
- Account for swap premium accrual after swaps.
- Keep pool-specific senior/junior insurance accounting without forking Uniswap.

The hook deliberately avoids return-delta swap logic in the MVP. The current v4 router funds the insurance reserve alongside a real PoolManager swap; the production extension can add custom accounting for direct PoolManager fee custody after the core mechanism is tested.

## Architecture

```text
Trader swap
   |
   v
RiskShieldPoolRouter.swapAndFundPremium
   - funds the RiskShield reserve premium path
   - unlocks PoolManager
   |
   v
RiskShieldHook.beforeSwap
   - calculates dynamic premium fee
   - returns v4 dynamic fee override
   |
   v
Uniswap v4 PoolManager.swap
   |
   v
RiskShieldHook.afterSwap
   - records premium estimate for pool analytics
   |
   v
RiskShieldVault
   - junior capital reserve
   - premium reserve
   - senior position accounting
   - covered IL settlement
```

## Contracts

- `RiskShieldHook.sol`: Uniswap v4 hook callback surface and premium fee calculation.
- `RiskShieldVault.sol`: Senior positions, junior reserves, premium accounting, and IL compensation.
- `RiskShieldPoolRouter.sol`: Demo router for real PoolManager initialize, liquidity, swap, and premium funding flows.
- `HookDeployer.sol`: Minimal CREATE2 deployer used to mine the hook permission address.
- `InsuranceMath.sol`: Pure premium, value, and coverage math.
- `MockUSDC.sol`: 6-decimal local reserve token.
- `MockRiskAsset.sol`: 18-decimal local volatile token.

## MVP Flow

1. Alice opens a senior LP accounting position through v4 liquidity addition hook data.
2. Bob deposits USDC as junior first-loss reserve capital.
3. Traders swap through the v4 pool.
4. The hook raises fees for larger or more volatile swaps.
5. Premiums accrue into RiskShield's reserve accounting through the router path.
6. Alice exits after an adverse price move.
7. RiskShield pays covered IL from the available reserve, capped by coverage limits and actual reserve balance.

## Unichain Sepolia

Primary demo chain: Unichain Sepolia

- Chain ID: `1301`
- RPC: `https://sepolia.unichain.org`
- PoolManager: `0x00b036b58a818b1bc34d502d3fe730db729e62ac`
- PositionManager: `0xf969aee60879c54baaed9f3ed26147db216fd664`
- StateView: `0xc199f1072a74d4e905aba1a84d9a45e2546b6222`
- PoolSwapTest: `0x9140a78c1a137c7ff1c151ec8231272af78a99a4`
- PoolModifyLiquidityTest: `0x5fa728c0a5cfd51bee4b060773f50554c0c8a7ab`
- Permit2: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

## Current Full v4 Deployment

```text
MockUSDC: 0xb0cD9Ec340036f47F4655d9BBfE1E172E3209A06
MockRiskAsset: 0x72290EB00a06c4a5582c64e8E336F6e4D242bE87
RiskShieldVault: 0xAE2fbD03F210206774BD2A43Bc96823a18022a5f
RiskShieldHook: 0xd9E54DB85EC7BbBFbFE1d47fae90b941aA4aC7C0
RiskShieldPoolRouter: 0x11fB0B3C8355fF826a3BC9316ea5B0A46E2FF0C0
Pool ID: 0xf7ab8f4eeb4e9ae1a8bf02a06f9d65aeeabefe42d29c38473c354eaaad1d4ba5
```

The hook address has the required `0x07c0` permission mask and the pool has been initialized on Unichain Sepolia.

## Local Setup

This repository expects Foundry.

```bash
forge test -vv
forge test --gas-report
npm run compile
npm run build
```

Create a local `.env` before deploying:

```bash
cp .env.example .env
```

Then fill:

- `PRIVATE_KEY`
- `UNICHAIN_SEPOLIA_RPC_URL`
- `ETHERSCAN_API_KEY`

The repo imports `v4-core` from the sibling folder cloned in this workspace:

```text
../v4-core
```

If you clone this repo elsewhere, install v4-core or update `remappings.txt`.

## Deployment

Deploy the full v4 integration:

```bash
forge script script/DeployV4RiskShield.s.sol:DeployV4RiskShield --rpc-url unichain_sepolia --broadcast
```

Run the real testnet smoke flow after deployment:

```bash
forge script script/SmokeV4RiskShield.s.sol:SmokeV4RiskShield --rpc-url unichain_sepolia --broadcast
```

The smoke flow mints mock assets, approves the router, adds liquidity through `PoolManager.modifyLiquidity`, swaps through `PoolManager.swap`, and funds the RiskShield reserve path.

The earlier standalone vault/hook logic deployment script is also available:

```bash
forge script script/DeployRiskShield.s.sol:DeployRiskShield --rpc-url unichain_sepolia --broadcast
```

See `DEPLOYMENTS.md` for the address log, transaction hashes, and smoke readbacks.

## Frontend

The Progress Update 2 frontend is a local demo surface for RiskShield's insurance accounting path.

```bash
npm run dev
```

Open `http://127.0.0.1:5173`.

The frontend can connect a wallet, show deployed addresses, calculate senior LP coverage previews, and interact with deployed mock USDC / vault addresses.

## Progress Updates

Progress Update 1:

- Repo created.
- README and architecture documented.
- Contract skeletons added.
- Initial tests added for math, reserves, and senior coverage.

Progress Update 2:

- Core tests passing.
- Full v4 deployment script ready and used on Unichain Sepolia.
- Hook address mined with correct v4 permission bits.
- Pool initialized through Unichain Sepolia PoolManager.
- Real v4 liquidity and swap smoke flow passed.

Final submission target:

- GitHub repo.
- 2-4 minute demo video.
- Tests and/or frontend.
- Polished Unichain Sepolia demo.
