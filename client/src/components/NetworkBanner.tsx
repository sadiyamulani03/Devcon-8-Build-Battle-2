"use client";

import { useNetwork } from "wagmi";
import { sepolia } from "wagmi/chains";

export function NetworkBanner() {
  const { chain } = useNetwork();
  const wrong = chain?.id !== sepolia.id;
  return (
    <div className="border-b border-slate-200 bg-slate-50 text-slate-700 text-xs px-4 py-2">
      {wrong ? (
        <span>
          Connected to {chain?.name ?? "unknown network"} (chainId{" "}
          {chain?.id ?? "—"}). Upstream is configured for Sepolia (chain ID
          11155111). Switch networks to use the deployed contract.
        </span>
      ) : (
        "Connected to Sepolia."
      )}
    </div>
  );
}
