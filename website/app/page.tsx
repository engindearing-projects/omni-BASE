import Navigation from '@/components/Navigation';
import Hero from '@/components/Hero';
import Capabilities from '@/components/Capabilities';
import AppShowcase from '@/components/AppShowcase';
import Features from '@/components/Features';
import Deployments from '@/components/Deployments';
import TechStack from '@/components/TechStack';
import Download from '@/components/Download';
import Footer from '@/components/Footer';

export default function Home() {
  return (
    <main className="relative bg-omni-navy min-h-screen">
      {/* Subtle background grid */}
      <div className="fixed inset-0 grid-bg pointer-events-none" />

      <Navigation />

      <div className="relative z-10">
        <Hero />
        <Capabilities />
        <AppShowcase />
        <Features />
        <Deployments />
        <TechStack />
        <Download />
        <Footer />
      </div>
    </main>
  );
}
