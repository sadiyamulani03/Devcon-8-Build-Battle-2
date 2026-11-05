import { useAccount } from "wagmi";
import { useIsRecipient, usePendingBalance, useCreditedBalance, useWithdraw } from "../hooks/useUpstreamFunding";
import { Button } from "../components/ui/button";
import { formatEther, IS_CONFIGURED } from "../lib/config";

export function RecipientDashboard() {
  const { address: account } = useAccount();
  const { data: isRecipient, isLoading: loadingRecipient } = useIsRecipient(account);
  const { data: pending, isLoading: loadingPending } = usePendingBalance(account);
  const { data: credited, isLoading: loadingCredited } = useCreditedBalance(account);
  const { withdraw, hash, isPending, isConfirming, isConfirmed, error } = useWithdraw();

  const connected = !!account;

  if (!IS_CONFIGURED) {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
        <p className="text-sm text-amber-800">Contract not configured. Set VITE_UPSTREAM_FUNDING_ADDRESS to a deployed address.</p>
      </div>
    );
  }

  if (!connected) {
    return (
      <div className="rounded-xl border border-slate-200 bg-white p-6 text-center">
        <h3 className="font-bold text-navy-900 mb-2">Connect your wallet</h3>
        <p className="text-sm text-slate-600 mb-4">Connect to check whether your wallet is a registered recipient.</p>
        <Button variant="outline">Connect wallet</Button>
      </div>
    );
  }

  if (loadingRecipient || loadingPending || loadingCredited) {
    return <p className="text-slate-500">Loading your recipient status…</p>;
  }

  if (!isRecipient) {
    return (
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <h2 className="text-2xl font-bold text-navy-900 mb-4">Recipient Dashboard</h2>
        <div className="rounded-lg border border-slate-200 bg-slate-50 p-6 text-center">
          <p className="text-slate-600 mb-3">Your wallet is not a registered recipient.</p>
          <p className="text-sm text-slate-500">Only registered recipients (maintainer, contributors, upstream dependencies) can withdraw from this contract.</p>
        </div>
      </div>
    );
  }

  const pendingWei = pending ?? 0n;
  const creditedWei = credited ?? 0n;

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-navy-900">Recipient Dashboard</h2>
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <p className="text-sm text-slate-500 mb-4">Your wallet is a registered recipient.</p>
        <div className="grid md:grid-cols-3 gap-4">
          <div>
            <p className="text-xs text-slate-500">Lifetime credited</p>
            <p className="text-lg font-mono font-bold text-navy-900">{formatEther(creditedWei)} ETH</p>
          </div>
          <div>
            <p className="text-xs text-slate-500">Pending (withdrawable)</p>
            <p className="text-lg font-mono font-bold text-green-600">{formatEther(pendingWei)} ETH</p>
          </div>
          <div>
            <p className="text-xs text-slate-500">Previously withdrawn</p>
            <p className="text-lg font-mono font-bold text-slate-600">{formatEther(creditedWei - pendingWei)} ETH</p>
          </div>
        </div>

        {pendingWei > 0n ? (
          <Button
            variant="destructive"
            onClick={() => withdraw()}
            disabled={isPending || isConfirming}
          >
            {isPending || isConfirming ? "Withdrawing…" : "Withdraw pending balance"}
          </Button>
        ) : (
          <p className="mt-2 text-sm text-slate-500">No pending balance to withdraw.</p>
        )}
      </div>

      {hash && (
        <div className="rounded-xl border border-slate-200 bg-white p-4">
          <p className="text-sm text-slate-700 mb-2">
            Withdrawal:{isConfirmed ? " Confirmed" : isPending || isConfirming ? " Pending" : " Submitted"}
          </p>
          <p className="text-sm text-slate-600 truncate">
            View on{" "}
            <a href={`https://sepolia.etherscan.io/tx/${hash}`} target="_blank" rel="noopener noreferrer" className="text-navy-600 hover:underline">
              Etherscan
            </a>
          </p>
        </div>
      )}

      {error && <p className="text-sm text-rose-600">{error.message ?? String(error)}</p>}
    </div>
  );
}
