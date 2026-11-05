# Sepolia Deployment — UpstreamFunding

## Status

**Deployed to Sepolia.** Contract address: `0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588`
Deployment transaction: `0x3ba4f63c0d98d2cf3d87fff667fa5f2120397aa655c0a2f515bed8c28c132855`
Deployment block: 12067987
Deployer: `0x81A4d25Ae3f981A67ab6098AA8Ea2b7B821d734E`
Etherscan: https://sepolia.etherscan.io/address/0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588

Never commit `.env` or any private key/mnemonic/RPC credentials.

---

## Prerequisites

* [Foundry](https://getfoundry.sh/) installed (`forge`, `cast`).
* A Sepolia-funded deployer ETH account (gas).
* Recipient addresses and shares defined in `.env` (see `.env.example`).

---

## 1. Pre-deployment Configuration

Copy `.env.example` to `.env` and fill in real values:

```bash
cp .env.example .env
```

Required variables:

| Variable | Description |
|----------|-------------|
| `SEPOLIA_RPC_URL` | Sepolia RPC endpoint (Infura, Alchemy, or public RPC) |
| `DEPLOYER_PRIVATE_KEY` | Deployer's private key (Sepolia ETH for gas) |
| `UPSTREAM_NAME_0..8` | Nine recipient human-readable names |
| `UPSTREAM_CAT_0..8` | Nine categories: 0 = maintainer, 1 = contributor, 2 = upstream dependency |
| `UPSTREAM_ADDR_0..8` | Nine unique, non-zero recipient addresses |
| `UPSTREAM_SHARE_0..8` | Nine shares in basis points (non-zero, sum = 10000) |

Documented split (must total 10000 BPS):

| Index | Role | Category | Share | % |
|-------|------|----------|-------|---|
| 0 | Maintainer | 0 | 3000 | 30.00% |
| 1–5 | Contributor (×5) | 1 | 800 each | 8.00% each |
| 6–8 | Upstream dependency (×3) | 2 | 1000 each | 10.00% each |

The deployment script (`script/Deploy.s.sol`) validates all of the above
locally **before** broadcasting any transaction:
* Missing variable → `MissingEnvVariable` (identifies the variable, not its value)
* Empty/zero/invalid value → `InvalidEnvValue` (identifies the variable)
* Category not 0/1/2 → `InvalidCategory`
* Zero or duplicate address → `InvalidEnvValue` / `DuplicateAddressConfig`
* Share total ≠ 10000 → `InvalidTotalSharesConfig`

If any validation fails, the script reverts **before** `vm.startBroadcast()`,
so no transaction is sent and no gas is wasted on a malformed deployment.

The constructor performs a second, independent validation round. If the
constructor reverts, the broadcast transaction consumes gas but makes no
state change and deploys no contract.

**Never export or paste your `DEPLOYER_PRIVATE_KEY` into ChatGPT or any
external service.**

### Signing methods

Foundry supports three ways to sign the deployment transaction:

#### Method 1: Private key via `--private-key` flag (default)

```bash
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast
```

**Operational risks:** Passing the private key on the command line may expose it in
shell history (`~/.bash_history`), process listings (`ps aux`), and container logs.
Mitigate by exporting it into the shell only for the duration of the deploy
command and clearing history afterward. Never commit the key to version control.

#### Method 2: Encrypted keystore (`--keystore` + `--password`)

If your deployer key is stored in an encrypted keystore file:

```bash
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --keystore /path/to/keystore.json \
  --password $KEYSTORE_PASSWORD \
  --broadcast
```

The keystore password must be provided via environment variable, never inline.

#### Method 3: Hardware wallet (`--hw-wallet`)

Foundry 1.8.7 supports hardware wallet signing via `--hw-wallet` for compatible
signers (e.g., Ledger, Trezor):

```bash
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --hw-wallet \
  --broadcast
```

Hardware wallet support depends on the installed signer software and USB/Bluetooth
connectivity. Test with `--sig "run()"` (simulation) before broadcasting.

**Recommendation:** Use a hardware wallet or encrypted keystore for production
deployments. Reserve `--private-key` for testing or air-gapped environments.


---

## 2. Simulation (No Broadcast)

Simulates execution against Sepolia via RPC. Reports chain ID, deployer
address, recipient configuration, total allocation, and estimated deployment
gas. **Does not broadcast a transaction. Does not deploy a contract.**

```bash
set -a
source .env
set +a

forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --sig "run()"
```

All output is labeled as simulation. No contract address is real until the
actual deployment command below is executed.

---

## 3. Actual Deployment (Broadcasts and Spends Sepolia ETH)

Clearly marked: this command sends a transaction to Sepolia and spends
deployer ETH. Requires explicit human execution.

```bash
set -a
source .env
set +a

forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast
```

Network guard: the script contains `require(block.chainid == 11155111)`.
If connected to any network other than Sepolia, it reverts before deploying.

After a successful deployment, record:

* Contract address (printed in output)
* Deployment transaction hash (from broadcast output)
* Deployer address
* Recipient configuration used

---

## 4. Contract Verification (Etherscan Sepolia)

`ETHERSCAN_API_KEY` must be set in the shell only. Never commit it.

Constructor arguments (all four parameters):

* `_names`: `string[]` (9 names)
* `_categories`: `uint8[]` (9 categories: 0/1/2)
* `_addresses`: `address[]` (9 addresses)
* `_shares`: `uint16[]` (9 shares in bps)

Generate the ABI-encoded constructor arguments:

```bash
cast abi-encode \
  "constructor(string[],uint8[],address[],uint16[])" \
  '["Alice Maintainer","Bob Contributor","Carol Contributor","Dave Contributor","Eve Contributor","Frank Contributor","Dep Alpha","Dep Beta","Dep Gamma"]' \
  '[0,1,1,1,1,1,2,2,2]' \
  '["<ADDR_0>","<ADDR_1>","<ADDR_2>","<ADDR_3>","<ADDR_4>","<ADDR_5>","<ADDR_6>","<ADDR_7>","<ADDR_8>"]' \
  '[3000,800,800,800,800,800,1000,1000,1000]'
```

Then verify:

```bash
forge verify-contract 0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588 UpstreamFunding \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args <ABI-ENCODED-HEX>
```

Alternatively, verify via the Etherscan UI:
https://sepolia.etherscan.io/address/0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588#code

Compiler settings (must match for verification):

* Solidity: 0.8.24
* Optimizer: enabled, 2000 runs
* EVM version: default (no `via_ir`)

---

## 5. Frontend Configuration

After deployment, configure the frontend:

```bash
cd client
cat > .env <<'EOF'
VITE_UPSTREAM_FUNDING_ADDRESS=0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588
VITE_SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
EOF
```

* `VITE_UPSTREAM_FUNDING_ADDRESS` — the deployed contract address: `0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588`
* `VITE_SEPOLIA_RPC_URL` — your Sepolia RPC URL
* Chain ID is hardcoded to `11155111` (Sepolia)

The frontend refuses to represent an unconfigured contract as deployed:
`IS_CONFIGURED` is `false` when the address is empty, disabling the sponsor
flow and showing a configuration notice on read-only pages.

A frontend rebuild and redeployment is required after changing production
environment variables:

```bash
cd client
npm install
npm run typecheck   # tsc --noEmit
npm run build       # tsc --noEmit && vite build
```

---

## 6. Deployment Evidence Checklist

| Field | Value |
|-------|-------|
| Sepolia contract address | `0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588` |
| Deployment transaction hash | `0x3ba4f63c0d98d2cf3d87fff667fa5f2120397aa655c0a2f515bed8c28c132855` |
| Deployment block | 12067987 |
| Deployer address | `0x81A4d25Ae3f981A67ab6098AA8Ea2b7B821d734E` |
| Chain ID | `11155111` |
| Constructor recipient configuration | Index 0: Maintainer (0, 3000 bps); Indices 1-5: Contributors (1, 800 bps); Indices 6-8: Upstream dependencies (2, 1000 bps) |
| Verification status | Submitted to Sourcify (Job: bf326ba0-7547-4e87-bfc1-a376bc026e2b). Etherscan verification pending (no Etherscan API key configured). |
| Etherscan verification URL | https://sepolia.etherscan.io/address/0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588 |
| Sourcify verification URL | https://sourcify.dev/server/verify-ui/jobs/bf326ba0-7547-4e87-bfc1-a376bc026e2b |
| Frontend URL | Pending (frontend not yet hosted) |
| Contract test results | 34 passed, 0 failed ✅ |
| Frontend typecheck | PASS ✅ |
| Frontend production build | Pending (requires `npm install && npm run build` in `client/`) |

---

## 7. What is NOT Deployed

There is no owner, no admin, and no emergency-sweep function. Once deployed,
the funding split is immutable and no party can move credited recipient funds.
Forced ETH (e.g. SELFDESTRUCT) is not attributable and cannot be swept.
