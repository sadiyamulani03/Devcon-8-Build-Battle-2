import { useAllRecipients } from "../hooks/useUpstreamFunding";
import { formatEther, formatShare } from "../lib/config";
import { Card } from "../components/ui/card";
import { AddressLink } from "../components/ui/address-link";

type RecipientRow = NonNullable<
  NonNullable<ReturnType<typeof useAllRecipients>["data">>[number]
>;

export function UpstreamDependencies() {
  const { data: recipients, isLoading } = useAllRecipients();

  if (isLoading) {
    return <p className="text-slate-500">Loading dependencies from contract…</p>;
  }

  const rows: RecipientRow[] = (recipients ?? []).filter(
    (r): r is RecipientRow => !!r
  );
  const deps = rows.filter((r) => r[2] === 2);

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <span className="w-2 h-2 rounded-full bg-purple-600"></span>
        <h2 className="text-2xl font-bold text-navy-900">Upstream dependencies</h2>
      </div>
      <p className="text-slate-600 max-w-2xl">
        This project depends on open-source libraries maintained by other teams. Those
        maintainers deserve a share of sponsorship automatically — they are funded in
        proportion to their importance, without the project maintainer acting as
        intermediary.
      </p>

      <div className="grid md:grid-cols-3 gap-4">
        {deps.map((row, i) => {
          const [addr, name, , shareBps, credited, withdrawn] = row;
          return (
            <DepCard
              key={i}
              name={name}
              addr={addr}
              share={shareBps}
              credited={credited}
              pending={credited - withdrawn}
            />
          );
        })}
        {deps.length === 0 && (
          <div className="col-span-full rounded-xl border border-slate-200 bg-white p-6 text-center">
            <p className="text-slate-600 text-sm">No upstream dependencies registered.</p>
          </div>
        )}
      </div>

      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <h3 className="font-bold text-navy-900 mb-3">Why dependency maintainers get funded automatically</h3>
        <ul className="text-sm text-slate-600 space-y-2 list-disc pl-5">
          <li>
            Open-source projects stand on the shoulders of other open-source projects.
            Dependency maintainers carry real maintenance burden but rarely receive direct
            funding.
          </li>
          <li>
            By routing a fixed share of every sponsorship directly to dependencies, Upstream
            makes that support automatic, neutral, and impossible to revoke unilaterally.
          </li>
          <li>
            Funds are credited to each dependency&rsquo;s own address and withdrawn
            independently — the project maintainer never holds dependency money.
          </li>
        </ul>
      </div>
    </div>
  );
}

function DepCard({ name, addr, share, credited, pending }: { name: string; addr: string; share: number; credited: bigint; pending: bigint }) {
  return (
    <Card className="border-purple-200 bg-purple-50/40">
      <div className="flex items-center justify-between mb-2">
        <h3 className="font-bold text-navy-900">{name}</h3>
        <span className="text-xs font-mono border border-purple-200 text-purple-700 bg-purple-50 px-2 py-0.5 rounded">{formatShare(share)}%</span>
      </div>
      <p className="text-xs text-slate-500 truncate mb-3">
        <AddressLink address={addr} />
      </p>
      <div className="flex justify-between items-baseline text-sm">
        <span className="font-mono text-navy-900">{formatEther(credited)} ETH</span>
        <span className="text-xs text-slate-400">credited</span>
      </div>
      <div className="flex justify-between items-baseline text-sm text-green-600 font-mono">
        <span>{formatEther(pending)} ETH</span>
        <span className="text-xs text-slate-400">pending</span>
      </div>
    </Card>
  );
}
