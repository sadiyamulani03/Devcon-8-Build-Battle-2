"use client";

import { useNavigate } from "react-router-dom";
import { ConnectButton } from "./ConnectButton";
import { Button } from "./ui/button";

const LINKS: { to: string; label: string }[] = [
  { to: "/", label: "Home" },
  { to: "/dashboard", label: "Funding Dashboard" },
  { to: "/allocation", label: "Allocation Explorer" },
  { to: "/sponsor", label: "Sponsor" },
  { to: "/recipient", label: "Recipient Dashboard" },
  { to: "/dependencies", label: "Upstream Dependencies" },
  { to: "/transparency", label: "Transparency" },
];

export function Nav() {
  const navigate = useNavigate();
  return (
    <nav className="sticky top-0 z-20 border-b border-slate-200 bg-white/80 backdrop-blur-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center gap-2">
            <span className="text-navy-900 font-bold text-xl tracking-tight">UPSTREAM</span>
            <span className="text-xs font-mono text-green-600 bg-green-100 px-2 py-0.5 rounded">Protocol</span>
          </div>
          <div className="hidden md:flex items-center gap-1">
            {LINKS.map((link) => (
              <Button
                key={link.to}
                variant="ghost"
                size="sm"
                onClick={() => navigate(link.to)}
                className={link.to === "/" ? "bg-slate-100 text-navy-900" : undefined}
              >
                {link.label}
              </Button>
            ))}
          </div>
          <div className="flex items-center gap-3">
            <ConnectButton className="hidden md:block" />
          </div>
        </div>
      </div>
    </nav>
  );
}
