import { useAllRecipients } from "../hooks/useUpstreamFunding";
import { formatEther, formatShare, CATEGORY_LABELS, CATEGORY_COLORS } from "../lib/config";
import { AddressLink } from "../components/ui/address-link";

type RecipientRow = NonNullable<
  NonNullable<ReturnType<typeof useAllRecipients>["data">>[number]
>;

export function AllocationExplorer() {
  const { data: recipients, isLoading, refetch } = useAllRecipients();

  if (isLoading) {
    return <p className="text-slate-500">Loading allocation from contract…</p>;
  }

  // Individual reads can fail independently; skip failures rather than
  // replacing them with misleading data.
  const rows: RecipientRow[] = (recipients ?? []).filter(
    (r): r is RecipientRow => !!r
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-navy-900">Allocation Explorer</h2>
        <button
          onClick={() => refetch()}
          className="text-xs text-navy-600 hover:underline"
          disabled={isLoading}
        >
          Refresh
        </button>
      </div>
      <p className="text-slate-500 text-sm">
        Recipient names, categories, addresses, and shares are read directly from the
        deployed contract. Nothing is hardcoded in the frontend.
      </p>

      {rows.length === 0 && recipients && recipients.length > 0 && (
        <p className="text-sm text-rose-600">
          Unable to load recipient details. Refresh or check your connection.
        </p>
      )}

      <div className="rounded-xl border border-slate-200 bg-white overflow-hidden">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200">
              <th className="px-4 py-3 text-slate-500 font-medium">#</th>
              <th className="px-4 py-3 text-slate-500 font-medium">Name</th>
              <th className="px-4 py-3 text-slate-500 font-medium">Category</th>
              <th className="px-4 py-3 text-slate-500 font-medium text-right">Share</th>
              <th className="px-4 py-3 text-slate-500 font-medium text-right">Address</th>
              <th className="px-4 py-3 text-slate-500 font-medium text-right">Credited</th>
              <th className="px-4 py-3 text-slate-500 font-medium text-right">Pending</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {rows.map((row, i) => {
              const [addr, name, category, shareBps, credited, withdrawn] = row;
              return (
                <tr key={i} className="hover:bg-slate-50/50">
                  <td className="px-4 py-3 text-slate-400">#{i + 1}</td>
                  <td className="px-4 py-3 font-medium text-navy-900">{name}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${
                      category === 0 ? "text-green-600 bg-green-50 border-green-200"
                      : category === 1 ? "text-blue-600 bg-blue-50 border-blue-200"
                      : "text-purple-600 bg-purple-50 border-purple-200"
                    }`}>
                      {category === 0 ? "Maintainer" : category === 1 ? "Contributor" : "Upstream dependency"}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right font-mono text-navy-900">
                    {formatShare(shareBps)}%
                  </td>
                  <td className="px-4 py-3 text-right">{<AddressLink address={addr} />}</td>
                  <td className="px-4 py-3 text-right font-mono">{formatEther(credited)} ETH</td>
                  <td className="px-4 py-3 text-right font-mono text-green-600">
                    {formatEther(credited - withdrawn)} ETH
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <h3 className="font-bold text-navy-900 mb-3">How the split works</h3>
        <ul className="text-sm text-slate-600 space-y-2 list-disc pl-5">
          <li>Shares are expressed in basis points (10000 = 100%).</li>
          <li>Each sponsorship is divided proportionally by share using integer arithmetic.</li>
          <li>Any rounding remainder is assigned to the designated remainder recipient (the maintainer), so nothing is left unattributed.</li>
          <li>The total of all shares always equals 10000 bps (100%).</li>
        </ul>
      </div>
    </div>
  );
}
