"use client";

import * as React from "react";

export interface AddressLinkProps {
  address: string;
}

export function AddressLink({ address }: AddressLinkProps) {
  const short = `${address.slice(0, 6)}…${address.slice(-4)}`;
  return (
    <a
      href={`https://sepolia.etherscan.io/address/${address}`}
      target="_blank"
      rel="noopener noreferrer"
      className="text-navy-600 hover:underline font-mono text-xs break-all"
      title={address}
    >
      {short}
    </a>
  );
}
