import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { createWagmiConfig } from "./lib/wagmi";
import { Router } from "./Router";

const queryClient = new QueryClient();

function App() {
  return (
    <WagmiProvider config={createWagmiConfig()}>
      <QueryClientProvider client={queryClient}>
        <Router />
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
