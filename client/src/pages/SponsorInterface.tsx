import { useState } from "react";
import { useAccount, useNetwork } from "wagmi";
import { parseEther } from "viem";
import { sepolia } from "wagmi/chains";
import { useSponsor } from "../hooks/useUpstreamFunding";
import { Button } from "../components/ui/button";
import { IS_CONFIGURED, explorerTxUrl } from "../lib/config";

export function SponsorInterface() {
  const { address: account } = useAccount();
  const { chain } = useNetwork();
  const { sponsor, hash, isPending, isConfirming, isConfirmed, error } = useSponsor();
  const [amount, setAmount] = useState("");
  const [txHash, setTxHash] = useState<string | null>(null);

  const onSepolia = chain?.id === sepolia.id;
  const ready = IS_CONFIGURED && onSepolia && !!account;

  function handleAmountChange(e: React.ChangeEvent<HTMLInputElement>) {
    setAmount(e.target.value);
    setTxHash(null);
  }

  async function handleSponsor(e: React.FormEvent) {
    e.preventDefault();
    const ether = parseFloat(amount);
    if (!ether || ether <= 0) return;
    const wei = parseEther(ether.toString());
    try {
      sponsor(wei);
    } catch {
      // writeContract error surfaced via `error`
    }
  }

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-navy-900">Sponsor the project</h2>
      <p className="text-slate-600 max-w-xl">
        Send ETH to the deployed UpstreamFunding contract. Funds are automatically
        allocated to the maintainer, contributors, and upstream dependencies according
        to the on-chain split. Accounting is derived from the actual amount sent — no
        caller-supplied amount is trusted.
      </p>

      {!IS_CONFIGURED ? (
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
          <p className="text-sm text-amber-800">
            Contract not configured. Set VITE_UPSTREAM_FUNDING_ADDRESS to a deployed
            UpstreamFunding address on Sepolia to enable sponsorship.
          </p>
        </div>
      ) : (
        <form onSubmit={handleSponsor} className="rounded-xl border border-slate-200 bg-white p-6">
          <div className="grid md:grid-cols-2 gap-4">
            <div className="col-span-full md:col-span-1">
              <label className="block text-sm font-medium text-slate-700 mb-1">Amount (ETH)</label>
              <div className="relative">
                <input
                  type="number"
                  step="any"
                  min="0"
                  value={amount}
                  onChange={handleAmountChange}
                  placeholder="e.g. 0.1"
                  className="w-full border border-slate-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-navy-500 focus:border-navy-500 outline-none"
                />
                <span className="absolute right-3 top-3 text-slate-400 text-sm">ETH</span>
              </div>
            </div>
            <div className="md:col-span-1 flex items-end">
              <Button
                type="submit"
                variant="destructive"
                disabled={!ready || isPending || isConfirming}
                className="w-full"
              >
                {isPending || isConfirming ? "Processing…" : "Sponsor"}
              </Button>
            </div>
          </div>

          {!ready && (
            <p className="mt-4 text-sm text-slate-500">
              {onSepolia ? "Connect your wallet to sponsor." : "Switch to Sepolia and connect your wallet."}
            </p>
          )}
        </form>
      )}

      {hash && (
        <div className="rounded-xl border border-slate-200 bg-white p-4">
          <p className="text-sm text-slate-700 mb-2">
            Status:{isConfirmed ? "Confirmed" : isPending || isConfirming ? "Pending" : "Submitted"}
          </p>
          <p className="text-sm text-slate-600 truncate">
            <a href={explorerTxUrl(hash)} target="_blank" rel="noopener noreferrer" className="text-navy-600 hover:underline">
              View on Etherscan
            </a>
            <span className="ml-2 text-xs text-slate-400 font-mono">{hash}</span>
          </p>
        </div>
      )}

      {error && (
        <p className="text-sm text-rose-600">{error.message ?? String(error)}</p>
      )}
    </div>
  );
}
