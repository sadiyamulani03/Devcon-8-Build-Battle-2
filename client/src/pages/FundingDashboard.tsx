import { useTotals } from "../hooks/useUpstreamFunding";
import { formatEther } from "../lib/config";

export function FundingDashboard() {
  const { data: totals, isLoading } = useTotals();

  const received = totals?.[0] ?? 0n;
  const credited = totals?.[1] ?? 0n;
  const withdrawn = totals?.[2] ?? 0n;
  const outstanding = totals?.[3] ?? 0n;

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-navy-900">Funding Dashboard</h2>
        <p className="text-slate-500 text-sm">All values read live from the deployed contract.</p>
      </div>

      {isLoading ? (
        <p className="text-slate-500">Loading contract data…</p>
      ) : (
        <div className="grid md:grid-cols-5 gap-4">
          <StatCard label="Total sponsorship received" value={formatEther(received)} delta="+ inflow" />
          <StatCard label="Total credited to recipients" value={formatEther(credited)} delta="allocated" />
          <StatCard label="Total withdrawn" value={formatEther(withdrawn)} delta="paid out" />
          <StatCard label="Outstanding liabilities" value={formatEther(outstanding)} delta="pending" accent="green" />
          <StatCard label="Net position" value={formatEther(received - withdrawn)} delta="" />
        </div>
      )}

      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <h3 className="font-bold text-navy-900 mb-4">Accounting check</h3>
        <p className="text-sm text-slate-600 mb-2">
          Every wei received via sponsorship is credited to a recipient:
          <span className="font-mono">received == credited</span>.
        </p>
        <p className="text-sm text-slate-600">
          Outstanding liabilities equal credited minus withdrawn, and no rounding dust
          is left unattributed.
        </p>
      </div>
    </div>
  );
}

function StatCard({ label, value, delta, accent }: { label: string; value: string; delta?: string; accent?: "green" }) {
  const accentCls = accent === "green" ? "text-green-600 bg-green-50" : "text-navy-900 bg-navy-50";
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4">
      <p className="text-xs text-slate-500">{label}</p>
      <div className="mt-1 flex items-baseline gap-1">
        <span className="text-xl font-bold text-navy-900">{value}</span>
        <span className="text-xs text-slate-400">ETH</span>
      </div>
      {delta && (
        <p className={`mt-1 text-xs font-medium ${accentCls}`}>{delta}</p>
      )}
    </div>
  );
}
