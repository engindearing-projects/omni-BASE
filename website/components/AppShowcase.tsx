'use client';

import { motion } from 'framer-motion';
import Image from 'next/image';

export default function AppShowcase() {
  const screenshots = [
    {
      image: '/screenshots/map-tactical-overlay.jpg',
      title: 'Real-Time Tactical Map',
      description: 'Professional satellite imagery with polygon overlays and MGRS coordinates',
    },
    {
      image: '/screenshots/tools-menu.jpg',
      title: 'Comprehensive Tools',
      description: '23+ tactical tools including Teams, Chat, CASEVAC, Meshtastic, and more',
    },
    {
      image: '/screenshots/server-connections.jpg',
      title: 'Multi-Server Connectivity',
      description: 'Connect to multiple TAK servers with SSL/TLS and data package import',
    },
  ];

  return (
    <section id="showcase" className="relative py-24 md:py-32 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6">
        {/* Section header */}
        <div className="text-center mb-16">
          <motion.span
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="tag mb-4 inline-block"
          >
            See It In Action
          </motion.span>
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl font-bold mb-6 text-omni-white"
          >
            Tactical Awareness at Your Fingertips
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-lg text-omni-grey max-w-2xl mx-auto"
          >
            Professional-grade situational awareness designed for field operations
          </motion.p>
        </div>

        {/* Screenshot carousel */}
        <div className="relative">
          <div className="flex gap-6 overflow-x-auto pb-8 snap-x snap-mandatory no-scrollbar">
            {screenshots.map((screenshot, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="flex-shrink-0 snap-center first:pl-6 last:pr-6"
              >
                <div className="relative group">
                  {/* Phone frame */}
                  <div className="relative w-[280px] md:w-[320px]">
                    {/* CTA overlay at top */}
                    <div className="absolute -top-4 left-1/2 -translate-x-1/2 z-20 w-full px-4">
                      <div className="bg-omni-navy/95 backdrop-blur-sm border border-omni-accent/30 rounded-xl px-4 py-3 text-center shadow-lg">
                        <h3 className="text-sm md:text-base font-semibold text-omni-white mb-1">
                          {screenshot.title}
                        </h3>
                        <p className="text-xs text-omni-grey leading-relaxed">
                          {screenshot.description}
                        </p>
                      </div>
                    </div>

                    {/* Phone bezel */}
                    <div className="relative bg-omni-slate rounded-[3rem] p-2 shadow-2xl">
                      {/* Inner bezel */}
                      <div className="relative bg-black rounded-[2.5rem] overflow-hidden">
                        {/* Dynamic Island */}
                        <div className="absolute top-3 left-1/2 -translate-x-1/2 w-24 h-7 bg-black rounded-full z-10" />

                        {/* Screenshot */}
                        <div className="relative aspect-[9/19.5]">
                          <Image
                            src={screenshot.image}
                            alt={screenshot.title}
                            fill
                            className="object-cover"
                            sizes="(max-width: 768px) 280px, 320px"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Glow effect on hover */}
                    <div className="absolute inset-0 rounded-[3rem] bg-omni-accent/20 blur-2xl opacity-0 group-hover:opacity-100 transition-opacity -z-10" />
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* Scroll hint */}
          <div className="flex justify-center gap-2 mt-4">
            <span className="text-xs text-omni-grey-dark uppercase tracking-wider">Scroll to explore</span>
            <svg className="w-4 h-4 text-omni-grey-dark animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
            </svg>
          </div>
        </div>

        {/* App Store CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mt-16 text-center"
        >
          <a
            href="https://apps.apple.com/us/app/omnitakmobile/id6755246992"
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary inline-flex items-center gap-3"
          >
            <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
            </svg>
            <span>
              <span className="text-xs block opacity-80">Download on the</span>
              <span className="text-lg font-semibold">App Store</span>
            </span>
          </a>
        </motion.div>
      </div>
    </section>
  );
}
