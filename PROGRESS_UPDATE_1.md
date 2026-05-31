# UHI9 Progress Update 1

Project ID: `HK-UHI9-0946`

Project Name: RiskShield — Tranche-Based IL Insurance Hook

## What is built

- Created the initial Foundry-style repository.
- Added README with problem, solution, architecture, Unichain Sepolia targets, and demo flow.
- Added core MVP contracts:
  - `RiskShieldHook.sol`
  - `RiskShieldVault.sol`
  - `InsuranceMath.sol`
  - `MockUSDC.sol`
  - `MockRiskAsset.sol`
- Added initial tests covering senior position accounting, junior reserve deposits, premium funding, coverage caps, and no-IL exits.
- Added a deployment helper for Unichain Sepolia mock-token deployment.

## Current status

The contracts compile with `solc` using the local Uniswap `v4-core` checkout. Foundry is not installed on the current machine yet, so the next step is to run the Foundry test suite once `forge` is available.

## Blockers

- Need Foundry installed locally to run `forge test -vv` and `forge test --gas-report`.
- Need final decision on whether the demo uses testnet USDC or the included `MockUSDC`.

## Plan before Progress Update 2

- Run and fix the full Foundry test suite.
- Add a hook-specific test around `beforeSwap` premium fee overrides and `onlyPoolManager` access control.
- Improve deployment script notes for HookMiner / v4 hook address flags.
- Prepare a short demo script showing senior LP protection vs vanilla LP loss.

