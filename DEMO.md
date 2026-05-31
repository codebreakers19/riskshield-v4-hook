# RiskShield Demo Script

## 1. Problem

Normal LPs are exposed to impermanent loss and LVR. RiskShield makes that risk explicit by separating LP capital into senior protected capital and junior first-loss insurance capital.

## 2. Actors

- Alice: senior LP seeking protected liquidity yield.
- Bob: junior insurer seeking higher premium yield.
- Trader: creates swap flow and pays dynamic IL protection premiums.

## 3. Local Demo

Run:

```bash
forge test -vv
forge test --gas-report
npm run compile
```

Key scenarios to show:

- `testSeniorWithdrawalReceivesCoverageWhenILExists`
- `testSeniorCoverageIsCappedByReserve`
- `testNoCompensationWhenNoIL`
- `testLargerTickMoveCreatesHigherPremium`
- `testOnlyPoolManagerCanCallHookCallbacks`

## 4. Frontend Demo

Run:

```bash
npm run dev
```

Use the frontend to:

1. Review deployed or pending contract addresses.
2. Enter a junior reserve amount.
3. Enter senior position entry amounts and price.
4. Enter exit amounts and exit price.
5. Preview hold value, exit value, estimated loss, and covered amount.

The frontend is intentionally focused on the insurance accounting path. It does not claim native Uniswap interface routing because RiskShield uses dynamic fees.

## 5. Final Demo Video Structure

Target length: 2-4 minutes.

1. Explain LP bottleneck: passive LPs cannot price IL/LVR risk.
2. Show RiskShield mechanism: senior LP + junior insurer + premium reserve.
3. Run tests proving the core paths.
4. Show frontend preview of coverage math.
5. Show Unichain Sepolia deployment status or addresses if deployed.

