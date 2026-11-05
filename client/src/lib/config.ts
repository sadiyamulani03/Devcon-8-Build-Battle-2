export const CHAIN_ID_SEPOLIA = 11155111;

export const CHAIN_ID_LOCALHOST = 31337;

/**
 * Contract address of the deployed UpstreamFunding contract.
 * Configured via VITE_UPSTREAM_FUNDING_ADDRESS. No recipient split is
 * hardcoded here; all recipient data is read on-chain.
 */
export const UPSTREAM_FUNDING_ADDRESS = (import.meta.env
  .VITE_UPSTREAM_FUNDING_ADDRESS as string | undefined) ?? "";

/**
 * Whether the app is pointed at a live deployed contract. When empty,
 * read-only pages degrade gracefully and the sponsor flow is disabled.
 */
export const IS_CONFIGURED = UPSTREAM_FUNDING_ADDRESS.length > 0;

export const BPS_DENOMINATOR = 10000;

export const CATEGORY_LABELS: Record<number, string> = {
  0: "Maintainer",
  1: "Contributor",
  2: "Upstream dependency",
};

export const CATEGORY_COLORS: Record<number, string> = {
  0: "text-green-600 bg-green-50 border-green-200",
  1: "text-blue-600 bg-blue-50 border-blue-200",
  2: "text-purple-600 bg-purple-50 border-purple-200",
};

export function formatEther(wei: bigint | number): string {
  const ether = BigInt(typeof wei === "string" ? BigInt(wei) : wei);
  const whole = ether / 10n ** 18n;
  const frac = ether % 10n ** 18n;
  const fracStr = frac.toString().padStart(18, "0").slice(0, 6).replace(/0+$/, "");
  return fracStr.length > 0 ? `${whole}.${fracStr}` : `${whole}.0`;
}

export function formatShare(bps: number): string {
  return (bps / 100).toFixed(2);
}

export function explorerTxUrl(txHash: string): string {
  return `https://sepolia.etherscan.io/tx/${txHash}`;
}

export function explorerAddressUrl(address: string): string {
  return `https://sepolia.etherscan.io/address/${address}`;
}
