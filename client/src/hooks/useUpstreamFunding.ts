import {
  useReadContract,
  useReadContracts,
  useWriteContract,
  useWaitForTransactionReceipt,
  type Address,
} from "wagmi";
import { UpstreamFundingAbi } from "@/abis/UpstreamFunding";
import { UPSTREAM_FUNDING_ADDRESS, IS_CONFIGURED } from "@/lib/config";

export function contractConfig() {
  return {
    address: UPSTREAM_FUNDING_ADDRESS as Address,
    abi: UpstreamFundingAbi,
  };
}

/**
 * Unwrap a single `useReadContracts` result entry.
 *
 * wagmi v2 wraps every multi-contract read result as:
 *   { status: "success", result: T } | { status: "failure", error }
 *
 * Never treat the wrapper object as the raw contract return value.
 */
function unwrapReadResult<T>(item: {
  status: string;
  result?: T;
  error?: unknown;
} | undefined): T | undefined {
  return item?.status === "success" ? (item.result as T) : undefined;
}

export function useRecipientCount() {
  return useReadContract({
    ...contractConfig(),
    functionName: "recipientCount",
    query: {
      enabled: IS_CONFIGURED,
    },
  });
}

export function useRecipient(index: bigint | number) {
  return useReadContract({
    ...contractConfig(),
    functionName: "getRecipient",
    args: [BigInt(index as number)],
    query: {
      enabled: IS_CONFIGURED,
    },
  });
}

type RecipientTuple = [
  address: `0x${string}`,
  name: string,
  category: number,
  shareBps: number,
  credited: bigint,
  withdrawn: bigint
];

export function useAllRecipients() {
  const { data: countData } = useRecipientCount();
  const n = countData ?? 0n;

  const contracts = [];
  for (let i = 0n; i < n; i++) {
    contracts.push({
      ...contractConfig(),
      functionName: "getRecipient",
      args: [i],
    });
  }

  const { data: results, isLoading, refetch } = useReadContracts({
    contracts: IS_CONFIGURED && n > 0n ? contracts : [],
    query: {
      enabled: IS_CONFIGURED && n > 0n,
    },
  });

  return {
    data: results ? results.map((r) => unwrapReadResult<RecipientTuple>(r)) : undefined,
    isLoading,
    refetch,
  };
}

export function usePendingBalance(account: Address | undefined) {
  return useReadContract({
    ...contractConfig(),
    functionName: "pendingBalance",
    args: [account as Address],
    query: {
      enabled: IS_CONFIGURED && !!account,
    },
  });
}

export function useCreditedBalance(account: Address | undefined) {
  return useReadContract({
    ...contractConfig(),
    functionName: "creditedBalance",
    args: [account as Address],
    query: {
      enabled: IS_CONFIGURED && !!account,
    },
  });
}

export function useIsRecipient(account: Address | undefined) {
  return useReadContract({
    ...contractConfig(),
    functionName: "isRecipient",
    args: [account as Address],
    query: {
      enabled: IS_CONFIGURED && !!account,
    },
  });
}

export function useTotals() {
  const { data: results, isLoading } = useReadContracts({
    contracts: IS_CONFIGURED
      ? [
          { ...contractConfig(), functionName: "totalSponsorshipReceived" },
          { ...contractConfig(), functionName: "totalCredited" },
          { ...contractConfig(), functionName: "totalWithdrawn" },
          { ...contractConfig(), functionName: "outstandingLiabilities" },
        ]
      : [],
    query: {
      enabled: IS_CONFIGURED,
    },
  });

  return {
    data: results
      ? [
          unwrapReadResult<bigint>(results[0]),
          unwrapReadResult<bigint>(results[1]),
          unwrapReadResult<bigint>(results[2]),
          unwrapReadResult<bigint>(results[3]),
        ]
      : undefined,
    isLoading,
  };
}

export function useSponsor() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  function sponsor(amountWei: bigint) {
    writeContract({
      ...contractConfig(),
      functionName: "sponsor",
      value: amountWei,
    });
  }

  return { sponsor, hash, isPending, isConfirming, isConfirmed, error };
}

export function useWithdraw() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  function withdraw() {
    writeContract({
      ...contractConfig(),
      functionName: "withdraw",
    });
  }

  return { withdraw, hash, isPending, isConfirming, isConfirmed, error };
}
