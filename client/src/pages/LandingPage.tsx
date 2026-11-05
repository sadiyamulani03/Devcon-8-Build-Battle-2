import { useAccount, useNetwork } from "wagmi";
import { sepolia } from "wagmi/chains";
import { ConnectButton } from "../components/ConnectButton";
import { Button } from "../components/ui/button";
import { IS_CONFIGURED } from "../lib/config";

export function LandingPage() {
  const { isConnected } = useAccount();
  const { chain } = useNetwork();
  const onSepolia = chain?.id === sepolia.id;

  return (
    <div className="space-y-12">
      <section className="pt-8">
        <div className="max-w-3xl">
          <div className="inline-flex items-center gap-2 rounded-full border border-green-200 bg-green-50 px-3 py-1 text-xs font-semibold text-green-700 mb-4">
            Open-source funding protocol
          </div>
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight text-navy-900 leading-tight">
            Pay it upstream.{" "}
            <span className="block text-green-600 mt-2">Automatic funding for maintainers, contributors, and dependencies.</span>
          </h1>
          <p className="mt-6 text-lg text-slate-600 leading-relaxed">
            Upstream lets sponsors send ETH to a single contract address. The contract
            automatically attributes funds to a project maintainer, five contributors, and
            three upstream open-source dependencies — according to an immutable, on-chain
            split. Every recipient independently pulls their own earnings. No one custodies
            anyone else's money.
          </p>
          <div className="mt-8 flex flex-wrap gap-4">
            <Button
              asChild
              disabled={!isConnected || !onSepolia || !IS_CONFIGURED}
            >
              <a href="/sponsor">Sponsor the project</a>
            </Button>
            <Button variant="outline" asChild>
              <a href="/allocation">View allocation</a>
            </Button>
            <Button variant="outline" asChild>
              <a href="/transparency">Transparency</a>
            </Button>
          </div>
        </div>
      </section>

      <section className="border-t border-slate-200 pt-12">
        <h2 className="text-2xl font-bold text-navy-900 mb-8">Why Upstream</h2>
        <div className="grid md:grid-cols-3 gap-6">
          <FeatureCard
            title="One address, automatic split"
            description="Sponsors send ETH to a single contract. Accounting is derived exclusively from the actual amount received (msg.value) — never a caller-supplied figure."
          />
          <FeatureCard
            title="Recipients pull their own funds"
            description="Each maintainer, contributor, and dependency independently inspects their accrued balance and withdraws it. No custodian, no redirects."
          />
          <FeatureCard
            title="Immutable, transparent split"
            description="The funding allocation is fixed at deployment and can never be changed. Every cent of rounding remainder is allocated — nothing is left unattributed."
          />
        </div>
      </section>

      <section>
        <h2 className="text-2xl font-bold text-navy-900 mb-8">Why maintainers must not custody contributor funds</h2>
        <div className="max-w-3xl text-slate-600 leading-relaxed space-y-4">
          <p>
            In many funding flows, the maintainer receives all sponsorship and is expected
            to redistribute it to contributors and dependencies. That concentrates power
            and risk: the maintainer can delay, redirect, or withhold payments, and
            contributors have no on-chain claim.
          </p>
          <p>
            Upstream removes that trust assumption. The contract credits each recipient
            directly and enforces pull payments. The maintainer cannot withdraw, move, or
            freeze funds owed to anyone else — their only access is their own share, just
            like every other recipient.
          </p>
        </div>
      </section>

      <section className="border-t border-slate-200 pt-12 pb-12">
        <h2 className="text-2xl font-bold text-navy-900 mb-8">How it works</h2>
        <div className="grid md:grid-cols-3 gap-6 text-slate-600">
          <StepCard number="1" title="Sponsor" description="Send ETH to one contract address. The contract records the actual amount received." />
          <StepCard number="2" title="Allocate" description="Funds are split proportionally by the immutable share table. Rounding remainders go to the designated remainder recipient." />
          <StepCard number="3" title="Withdraw" description="Each recipient pulls their own pending balance independently via a reentrancy-guarded withdrawal." />
        </div>
      </section>
    </div>
  );
}

function FeatureCard({ title, description }: { title: string; description: string }) {
  return (
    <div className="p-6 rounded-xl border border-slate-200 bg-white">
      <h3 className="font-bold text-navy-900 mb-2">{title}</h3>
      <p className="text-sm text-slate-500">{description}</p>
    </div>
  );
}

function StepCard({ number, title, description }: { number: number; title: string; description: string }) {
  return (
    <div className="p-6 rounded-xl border border-slate-200 bg-white">
      <div className="w-8 h-8 rounded-full bg-navy-900 text-white text-xs flex items-center justify-center mb-3">{number}</div>
      <h3 className="font-bold text-navy-900 mb-2">{title}</h3>
      <p className="text-sm text-slate-500">{description}</p>
    </div>
  );
}
