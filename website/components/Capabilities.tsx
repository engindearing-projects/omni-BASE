'use client';

import { motion } from 'framer-motion';

export default function Capabilities() {
  const capabilities = [
    {
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
        </svg>
      ),
      title: 'Real-Time Tracking',
      description: 'See teammates on a tactical map with live position updates. Track assets, vehicles, and personnel in real time across any terrain.',
      highlights: ['GPS tracking', 'MGRS coordinates', 'Multi-layer maps'],
    },
    {
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      ),
      title: 'Secure Messaging',
      description: 'GeoChat integration enables encrypted team communication. Send text, locations, and tactical data with full CoT protocol support.',
      highlights: ['End-to-end encryption', 'Group channels', 'Location sharing'],
    },
    {
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8.111 16.404a5.5 5.5 0 017.778 0M12 20h.01m-7.08-7.071c3.904-3.905 10.236-3.905 14.14 0M1.394 9.393c5.857-5.857 15.355-5.857 21.213 0" />
        </svg>
      ),
      title: 'Off-Grid Mesh',
      description: 'Meshtastic integration enables long-range communication without cellular or WiFi. Stay connected when infrastructure fails.',
      highlights: ['LoRa mesh networking', 'Multi-hop relay', 'No infrastructure needed'],
    },
    {
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
        </svg>
      ),
      title: 'Enterprise Security',
      description: 'TLS 1.2/1.3 encryption, certificate authentication, and iOS Keychain integration. Deploy with confidence in sensitive environments.',
      highlights: ['TLS encryption', 'Certificate auth', 'Secure key storage'],
    },
  ];

  return (
    <section id="capabilities" className="relative py-24 md:py-32">
      <div className="max-w-7xl mx-auto px-6">
        {/* Section header */}
        <div className="text-center mb-16">
          <motion.span
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="tag mb-4 inline-block"
          >
            Key Capabilities
          </motion.span>
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl font-bold mb-6"
          >
            <span className="text-omni-white">Situational Awareness</span>
            <br />
            <span className="text-gradient">In Real Time</span>
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-lg text-omni-grey max-w-2xl mx-auto"
          >
            OmniTAK Mobile provides comprehensive tactical capabilities for defense operations,
            enabling real-time tracking, messaging, and mission coordination.
          </motion.p>
        </div>

        {/* Capabilities grid */}
        <div className="grid md:grid-cols-2 gap-6">
          {capabilities.map((capability, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              className="capability-card group"
            >
              <div className="flex items-start gap-4">
                <div className="feature-icon text-omni-accent shrink-0">
                  {capability.icon}
                </div>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-omni-white mb-2 group-hover:text-omni-accent transition-colors">
                    {capability.title}
                  </h3>
                  <p className="text-omni-grey mb-4 leading-relaxed">
                    {capability.description}
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {capability.highlights.map((highlight, j) => (
                      <span
                        key={j}
                        className="text-xs px-3 py-1 rounded-full bg-omni-slate-light/50 text-omni-grey-light border border-omni-border"
                      >
                        {highlight}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Cross-platform note */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mt-16 text-center"
        >
          <div className="inline-flex items-center gap-4 px-6 py-4 rounded-xl bg-omni-slate/50 border border-omni-border">
            <div className="flex items-center gap-2">
              <svg className="w-6 h-6 text-omni-grey" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <span className="text-sm text-omni-grey">iOS</span>
            </div>
            <div className="w-px h-6 bg-omni-border" />
            <div className="flex items-center gap-2">
              <svg className="w-6 h-6 text-omni-grey" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17.523 15.341l-.001-.001-5.155 2.98a.734.734 0 01-.735 0l-5.155-2.98-.001.001a.734.734 0 010-1.27l5.156-2.98a.734.734 0 01.735 0l5.155 2.98a.734.734 0 010 1.27zM12 1.5L3.5 6.25v9.5L12 20.5l8.5-4.75v-9.5L12 1.5z"/>
              </svg>
              <span className="text-sm text-omni-grey">Android</span>
            </div>
            <div className="w-px h-6 bg-omni-border" />
            <span className="text-sm text-omni-grey-dark">
              Connect with ATAK, WinTAK, and iTAK users
            </span>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
