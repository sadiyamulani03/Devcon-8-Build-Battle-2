import { http, createConfig, type Config } from "wagmi";
import { sepolia, localhost } from "wagmi/chains";

export function createWagmiConfig(): Config {
  return createConfig({
    chains: [sepolia, localhost],
    transports: {
      [sepolia.id]: http(
        import.meta.env.VITE_SEPOLIA_RPC_URL ||
          "https://sepolia.infura.io/v3/0x0000000000000000000000000000000000000000"
      ),
      [localhost.id]: http("http://127.0.0.1:8545"),
    },
  });
}
