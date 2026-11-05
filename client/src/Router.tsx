import { BrowserRouter, Routes, Route, useNavigate, useLocation } from "react-router-dom";
import { Nav } from "./components/Nav";
import { LandingPage } from "./pages/LandingPage";
import { FundingDashboard } from "./pages/FundingDashboard";
import { AllocationExplorer } from "./pages/AllocationExplorer";
import { SponsorInterface } from "./pages/SponsorInterface";
import { RecipientDashboard } from "./pages/RecipientDashboard";
import { UpstreamDependencies } from "./pages/UpstreamDependencies";
import { Transparency } from "./pages/Transparency";
import { NetworkBanner } from "./components/NetworkBanner";

export function Router() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-navy-50 text-slate-900 antialiased">
        <NetworkBanner />
        <Nav />
        <main className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
          <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route path="/dashboard" element={<FundingDashboard />} />
            <Route path="/allocation" element={<AllocationExplorer />} />
            <Route path="/sponsor" element={<SponsorInterface />} />
            <Route path="/recipient" element={<RecipientDashboard />} />
            <Route path="/dependencies" element={<UpstreamDependencies />} />
            <Route path="/transparency" element={<Transparency />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}
