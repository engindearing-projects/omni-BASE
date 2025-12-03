'use client';

import { motion } from 'framer-motion';

export default function Deployments() {
  const deployments = [
    {
      title: 'Search & Rescue Operations',
      description: 'Coordinate multi-team search operations with real-time position sharing, waypoint navigation, and off-grid mesh communication when cellular infrastructure is unavailable.',
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      ),
      stats: [
        { label: 'Coordination', value: 'Multi-team' },
        { label: 'Coverage', value: 'Off-grid' },
      ],
    },
    {
      title: 'Military & Defense',
      description: 'Full ATAK compatibility ensures seamless integration with existing TAK infrastructure. Connect with ATAK, WinTAK, and other TAK clients for unified tactical coordination.',
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
        </svg>
      ),
      stats: [
        { label: 'TAK Compatible', value: '100%' },
        { label: 'Protocol', value: 'CoT XML' },
      ],
    },
    {
      title: 'First Responders',
      description: 'Emergency services deploy quickly with GeoChat, tactical mapping, and secure team communication. Real-time situational awareness for incident commanders and field teams.',
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.879 16.121A3 3 0 1012.015 11L11 14H9c0 .768.293 1.536.879 2.121z" />
        </svg>
      ),
      stats: [
        { label: 'Deployment', value: 'Rapid' },
        { label: 'Messaging', value: 'Encrypted' },
      ],
    },
    {
      title: 'Disaster Response',
      description: 'When infrastructure fails, Meshtastic mesh networking keeps teams connected without cellular or WiFi. Deploy situational awareness where traditional communications are down.',
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      stats: [
        { label: 'Network', value: 'Mesh' },
        { label: 'Infrastructure', value: 'None required' },
      ],
    },
  ];

  return (
    <section id="deployments" className="relative py-24 md:py-32">
      <div className="max-w-7xl mx-auto px-6">
        {/* Section header */}
        <div className="text-center mb-16">
          <motion.span
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="tag mb-4 inline-block"
          >
            Deployment Scenarios
          </motion.span>
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl font-bold mb-6 text-omni-white"
          >
            Built for Real Missions
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-lg text-omni-grey max-w-2xl mx-auto"
          >
            Deployed by professionals who depend on reliable communication and situational awareness
          </motion.p>
        </div>

        {/* Deployments grid */}
        <div className="grid md:grid-cols-2 gap-8">
          {deployments.map((deployment, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              className="relative group"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-omni-accent/10 to-omni-teal/10 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="relative card p-8">
                <div className="flex items-start gap-4 mb-4">
                  <div className="feature-icon text-omni-accent shrink-0">
                    {deployment.icon}
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-omni-white mb-2 group-hover:text-omni-accent transition-colors">
                      {deployment.title}
                    </h3>
                  </div>
                </div>
                <p className="text-omni-grey leading-relaxed mb-6">
                  {deployment.description}
                </p>
                <div className="flex gap-6">
                  {deployment.stats.map((stat, j) => (
                    <div key={j}>
                      <div className="text-lg font-semibold text-omni-accent">{stat.value}</div>
                      <div className="text-xs text-omni-grey-dark uppercase tracking-wider">{stat.label}</div>
                    </div>
                  ))}
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Global deployment note */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mt-16"
        >
          <div className="card p-8 text-center">
            <div className="flex items-center justify-center gap-3 mb-4">
              <svg className="w-6 h-6 text-omni-teal" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <h3 className="text-xl font-semibold text-omni-white">Global Deployment Ready</h3>
            </div>
            <p className="text-omni-grey max-w-2xl mx-auto">
              OmniTAK Mobile is a fully exportable solution that can be deployed anywhere.
              Open source and MIT licensed for maximum flexibility in any operational environment.
            </p>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
