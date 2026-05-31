import { createWalletClient, custom, parseUnits } from "viem";
import { unichainSepolia } from "viem/chains";
import "./styles.css";

const DEFAULTS = {
  mockUSDC: "0xb0cD9Ec340036f47F4655d9BBfE1E172E3209A06",
  vault: "0xAE2fbD03F210206774BD2A43Bc96823a18022a5f",
  hook: "0xd9E54DB85EC7BbBFbFE1d47fae90b941aA4aC7C0",
  router: "0x11fB0B3C8355fF826a3BC9316ea5B0A46E2FF0C0",
  entryAmount0: "1",
  entryAmount1: "2000",
  exitAmount0: "0.5",
  exitAmount1: "1000",
  exitPrice: "2000",
  reserve: "2000",
  maxCoverageBps: "3000",
};

const poolId = "0xf7ab8f4eeb4e9ae1a8bf02a06f9d65aeeabefe42d29c38473c354eaaad1d4ba5";

const vaultAbi = [
  {
    type: "function",
    name: "depositJunior",
    stateMutability: "nonpayable",
    inputs: [
      { name: "poolId", type: "bytes32" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [],
  },
];

const erc20Abi = [
  {
    type: "function",
    name: "approve",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ type: "bool" }],
  },
  {
    type: "function",
    name: "mint",
    stateMutability: "nonpayable",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [],
  },
];

const state = {
  ...DEFAULTS,
  account: "",
  status: "Full v4 deployment on Unichain Sepolia. Connect wallet to interact with mock contracts.",
};

function numberValue(id) {
  const parsed = Number(document.querySelector(`#${id}`)?.value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

function previewCoverage() {
  const entryAmount0 = numberValue("entryAmount0");
  const entryAmount1 = numberValue("entryAmount1");
  const exitAmount0 = numberValue("exitAmount0");
  const exitAmount1 = numberValue("exitAmount1");
  const exitPrice = numberValue("exitPrice");
  const reserve = numberValue("reserve");
  const maxCoverageBps = numberValue("maxCoverageBps");

  const holdValue = entryAmount0 * exitPrice + entryAmount1;
  const exitValue = exitAmount0 * exitPrice + exitAmount1;
  const loss = Math.max(0, holdValue - exitValue);
  const maxCoverage = (holdValue * maxCoverageBps) / 10000;
  const coverable = Math.min(loss, maxCoverage, reserve);

  return { holdValue, exitValue, loss, maxCoverage, coverable };
}

async function walletClient() {
  if (!window.ethereum) throw new Error("No injected wallet found.");
  const [account] = await window.ethereum.request({ method: "eth_requestAccounts" });
  state.account = account;
  return createWalletClient({ account, chain: unichainSepolia, transport: custom(window.ethereum) });
}

async function writeContract({ address, abi, functionName, args }) {
  if (!address) throw new Error("Missing deployed contract address.");
  const client = await walletClient();
  const hash = await client.writeContract({ address, abi, functionName, args });
  state.status = `Transaction submitted: ${hash}`;
  render();
}

async function mintAndApproveJunior() {
  const amount = parseUnits(document.querySelector("#reserve").value || "0", 6);
  const client = await walletClient();
  await writeContract({
    address: document.querySelector("#mockUSDC").value,
    abi: erc20Abi,
    functionName: "mint",
    args: [client.account.address, amount],
  });
  await writeContract({
    address: document.querySelector("#mockUSDC").value,
    abi: erc20Abi,
    functionName: "approve",
    args: [document.querySelector("#vault").value, amount],
  });
}

async function depositJunior() {
  const amount = parseUnits(document.querySelector("#reserve").value || "0", 6);
  await writeContract({
    address: document.querySelector("#vault").value,
    abi: vaultAbi,
    functionName: "depositJunior",
    args: [poolId, amount],
  });
}

function field(id, label, value, suffix = "") {
  return `
    <label class="field" for="${id}">
      <span>${label}</span>
      <div>
        <input id="${id}" value="${value}" />
        ${suffix ? `<small>${suffix}</small>` : ""}
      </div>
    </label>
  `;
}

function metric(label, value) {
  return `<div class="metric"><span>${label}</span><strong>${value}</strong></div>`;
}

function dollar(value) {
  return `$${value.toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
}

function short(address) {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function showError(error) {
  state.status = error.shortMessage || error.message;
  render();
}

function render() {
  const preview = previewCoverage();
  document.querySelector("#app").innerHTML = `
    <section class="shell">
      <header class="topbar">
        <div>
          <p class="eyebrow">UHI9 / Impermanent Loss & Yield Systems</p>
          <h1>RiskShield</h1>
        </div>
        <button id="connect">${state.account ? short(state.account) : "Connect"}</button>
      </header>

      <section class="hero">
        <div>
          <h2>Tranche-based insurance for Uniswap v4 LPs.</h2>
          <p>Senior LPs get protected liquidity exposure. Junior insurers provide first-loss capital and earn premium yield. Traders fund the reserve through dynamic IL protection premiums.</p>
        </div>
        <div class="metric-grid">
          ${metric("Hold value", dollar(preview.holdValue))}
          ${metric("Exit value", dollar(preview.exitValue))}
          ${metric("Estimated loss", dollar(preview.loss))}
          ${metric("Coverable", dollar(preview.coverable))}
        </div>
      </section>

      <section class="layout">
        <div class="panel">
          <h3>Deployment</h3>
          ${field("mockUSDC", "MockUSDC", state.mockUSDC)}
          ${field("vault", "RiskShieldVault", state.vault)}
          ${field("hook", "RiskShieldHook", state.hook)}
          ${field("router", "PoolRouter", state.router)}
          <p class="note">Hook address has valid v4 permission bits and the pool is initialized. Native Uniswap interface routing is not claimed because this MVP uses dynamic fees.</p>
        </div>

        <div class="panel">
          <h3>Junior Insurer</h3>
          ${field("reserve", "Reserve amount", state.reserve, "USDC")}
          <div class="actions">
            <button id="mintApprove">Mint + Approve</button>
            <button id="depositJunior">Deposit Junior</button>
          </div>
        </div>

        <div class="panel">
          <h3>Senior LP Demo</h3>
          ${field("entryAmount0", "Entry token0", state.entryAmount0)}
          ${field("entryAmount1", "Entry USDC", state.entryAmount1)}
          <p class="note">The deployed smoke flow opened a senior position through real PoolManager liquidity modification.</p>
        </div>

        <div class="panel">
          <h3>Exit Simulation</h3>
          ${field("exitAmount0", "Exit token0", state.exitAmount0)}
          ${field("exitAmount1", "Exit USDC", state.exitAmount1)}
          ${field("exitPrice", "Exit price", state.exitPrice, "USDC/token0")}
          ${field("maxCoverageBps", "Coverage cap", state.maxCoverageBps, "bps")}
        </div>
      </section>

      <footer class="status">${state.status}</footer>
    </section>
  `;

  for (const id of Object.keys(DEFAULTS)) {
    const input = document.querySelector(`#${id}`);
    if (input) {
      input.addEventListener("input", () => {
        state[id] = input.value;
        if (!["mockUSDC", "vault", "hook", "router"].includes(id)) render();
      });
    }
  }

  document.querySelector("#connect").addEventListener("click", async () => {
    try {
      await walletClient();
      state.status = "Wallet connected.";
    } catch (error) {
      state.status = error.message;
    }
    render();
  });

  document.querySelector("#mintApprove").addEventListener("click", () => mintAndApproveJunior().catch(showError));
  document.querySelector("#depositJunior").addEventListener("click", () => depositJunior().catch(showError));
}

render();
