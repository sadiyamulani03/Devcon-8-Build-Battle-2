import { useAllRecipients, useTotals } from "../hooks/useUpstreamFunding";
import { IS_CONFIGURED, UPSTREAM_FUNDING_ADDRESS, formatEther } from "../lib/config";
import { Card, StatRow } from "../components/ui/card";
import { AddressLink } from "../components/ui/address-link";

type RecipientRow = NonNullable<
  NonNullable<ReturnType<typeof useAllRecipients>["data">>[number]
>;

export function Transparency() {
  const { data: recipients, isLoading: loadingRecipients } = useAllRecipients();
  const { data: totals, isLoading: loadingTotals } = useTotals();

  const loading = loadingRecipients || loadingTotals;
  const received = totals?.[0] ?? 0n;
  const credited = totals?.[1] ?? 0n;
  const withdrawn = totals?.[2] ?? 0n;
  const outstanding = totals?.[3] ?? 0n;

  if (!IS_CONFIGURED) {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50 p-6">
        <h2 className="text-2xl font-bold text-navy-900 mb-4">Transparency</h2>
        <p className="text-sm text-amber-800">
          Contract not configured. Set VITE_UPSTREAM_FUNDING_ADDRESS to a deployed
          Sepolia address.
        </p>
      </div>
    );
  }

  if (loading) {
    return <p className="text-slate-500">Loading on-chain data…</p>;
  }

  const allocationRows: RecipientRow[] = (recipients ?? []).filter(
    (r): r is RecipientRow => !!r
  );

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-navy-900">Transparency</h2>

      <Card>
        <h3 className="font-bold text-navy-900 mb-4">Contract</h3>
        <div className="grid md:grid-cols-2 gap-4 text-sm">
          <StatRow label="Address">
            <AddressLink address={UPSTREAM_FUNDING_ADDRESS} />
          </StatRow>
          <StatRow label="Network">Sepolia</StatRow>
          <StatRow label="Chain ID">11155111</StatRow>
          <StatRow label="Total sponsorship received">{formatEther(received)} ETH</StatRow>
          <StatRow label="Total credited">{formatEther(credited)} ETH</StatRow>
          <StatRow label="Total withdrawn">{formatEther(withdrawn)} ETH</StatRow>
          <StatRow label="Outstanding liabilities">{formatEther(outstanding)} ETH</StatRow>
        </div>
      </Card>

      <Card>
        <h3 className="font-bold text-navy-900 mb-4">On-chain recipient allocation</h3>
        <p className="text-sm text-slate-600 mb-3">
          Names, categories, addresses, and shares are read directly from the deployed
          contract — nothing is hardcoded in the frontend.
        </p>
        <div className="overflow-hidden rounded-lg border border-slate-200">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200">
                <th className="px-4 py-3 text-slate-500 font-medium">Name</th>
                <th className="px-4 py-3 text-slate-500 font-medium">Category</th>
                <th className="px-4 py-3 text-slate-500 font-medium text-right">Share</th>
                <th className="px-4 py-3 text-slate-500 font-medium text-right">Address</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {allocationRows.map((row, i) => {
                const [addr, name, category, shareBps] = row;
                return (
                  <tr key={i}>
                    <td className="px-4 py-3 font-medium text-navy-900">{name}</td>
                    <td className="px-4 py-3 text-slate-600">
                      {category === 0 ? "Maintainer" : category === 1 ? "Contributor" : "Upstream dependency"}
                    </td>
                    <td className="px-4 py-3 text-right font-mono">
                      {Number(shareBps) / 100}%
                    </td>
                    <td className="px-4 py-3 text-right">
                      <AddressLink address={addr} />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
