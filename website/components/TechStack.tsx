'use client';

import { motion } from 'framer-motion';

export default function TechStack() {
  const technologies = [
    { name: 'SwiftUI', desc: 'Modern iOS UI' },
    { name: 'Rust', desc: 'Core library' },
    { name: 'Kotlin', desc: 'Android native' },
    { name: 'MapKit', desc: 'iOS mapping' },
    { name: 'MapLibre', desc: 'Android maps' },
    { name: 'Meshtastic', desc: 'Mesh networking' },
    { name: 'Bazel', desc: 'Build system' },
    { name: 'TypeScript', desc: 'Android logic' },
  ];

  const protocols = [
    'CoT XML',
    'TLS 1.2/1.3',
    'TCP/UDP',
    'WebSocket',
    'KML/KMZ',
    'MGRS',
  ];

  return (
    <section id="tech" className="relative py-24 md:py-32 bg-omni-navy-light/30">
      <div className="max-w-7xl mx-auto px-6">
        {/* Section header */}
        <div className="text-center mb-16">
          <motion.span
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="tag mb-4 inline-block"
          >
            Technology Stack
          </motion.span>
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl font-bold mb-6 text-omni-white"
          >
            Built with Modern Tools
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-lg text-omni-grey max-w-2xl mx-auto"
          >
            Performance-optimized architecture for maximum reliability in the field
          </motion.p>
        </div>

        {/* Technologies grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-16">
          {technologies.map((tech, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.05 }}
              className="card card-hover p-5 text-center group"
            >
              <div className="font-semibold text-omni-white group-hover:text-omni-accent transition-colors text-lg">
                {tech.name}
              </div>
              <div className="text-xs text-omni-grey-dark mt-1">{tech.desc}</div>
            </motion.div>
          ))}
        </div>

        {/* Open Standards section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="card p-8"
        >
          <div className="text-center">
            <h3 className="text-xl font-semibold text-omni-white mb-4">Open Standards Compliance</h3>
            <p className="text-omni-grey mb-6 max-w-2xl mx-auto">
              Full compliance with TAK CoT XML protocol, TLS 1.2/1.3 security standards,
              and support for industry-standard formats.
            </p>
            <div className="flex flex-wrap justify-center gap-3">
              {protocols.map((protocol, i) => (
                <span
                  key={i}
                  className="px-4 py-2 rounded-lg bg-omni-slate-light/50 text-omni-accent text-sm font-mono border border-omni-border"
                >
                  {protocol}
                </span>
              ))}
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
