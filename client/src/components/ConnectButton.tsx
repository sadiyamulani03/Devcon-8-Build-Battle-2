"use client";

import {
  useConnect,
  useDisconnect,
  useAccount,
  useNetwork,
  type ConfigParameter,
} from "wagmi";
import { Button } from "./ui/button";

export function ConnectButton(props: ConfigParameter & { className?: string }) {
  const { connect, connectors, pending } = useConnect();
  const { disconnect } = useDisconnect();
  const { address, isConnected } = useAccount();
  const { chain } = useNetwork();

  const isSepolia = chain?.id === 11155111;

  if (isConnected) {
    return (
      <Button
        variant="destructive"
        onClick={() => disconnect()}
        className={props.className}
        size="sm"
      >
        Disconnect
      </Button>
    );
  }

  const noConnectors = connectors.length === 0;

  return (
    <Button
      onClick={() => {
        if (noConnectors) return;
        connect({ connector: connectors[0] });
      }}
      disabled={pending || noConnectors}
      className={props.className}
      size="sm"
    >
      {noConnectors ? "No compatible wallet found" : pending ? "Connecting…" : "Connect wallet"}
    </Button>
  );
}
