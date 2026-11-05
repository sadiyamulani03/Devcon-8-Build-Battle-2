"use client";

import * as React from "react";

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

export function Card({ className, children, ...props }: CardProps) {
  return (
    <div
      className={["rounded-xl border border-slate-200 bg-white p-6", className].filter(Boolean).join(" ")}
      {...props}
    >
      {children}
    </div>
  );
}

export interface StatRowProps {
  label: string;
  value: React.ReactNode;
  note?: string;
}

export function StatRow({ label, value, note }: StatRowProps) {
  return (
    <div className="flex justify-between items-baseline py-2 text-sm border-b border-slate-100 last:border-0">
      <span className="text-slate-500">{label}</span>
      <div className="flex items-baseline gap-1">
        <span className="font-medium text-navy-900">{value}</span>
        {note && <span className="text-xs text-slate-400">{note}</span>}
      </div>
    </div>
  );
}
