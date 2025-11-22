import Navigation from '@/components/Navigation';
import Hero from '@/components/Hero';
import Features from '@/components/Features';
import UseCases from '@/components/UseCases';
import TechStack from '@/components/TechStack';
import Changelog from '@/components/Changelog';
import Download from '@/components/Download';
import Footer from '@/components/Footer';
import FloatingParticles from '@/components/FloatingParticles';
import GridBackground from '@/components/GridBackground';

export default function Home() {
  return (
    <main className="relative">
      <GridBackground />
      <FloatingParticles />
      <Navigation />

      <div className="relative z-10">
        <Hero />
        <Features />
        <UseCases />
        <TechStack />
        <Changelog />
        <Download />
        <Footer />
      </div>
    </main>
  );
}
