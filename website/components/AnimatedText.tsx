'use client';

import { motion } from 'framer-motion';
import { ReactNode } from 'react';

interface AnimatedTextProps {
  children: ReactNode;
  className?: string;
  delay?: number;
  gradient?: boolean;
}

export default function AnimatedText({ children, className = '', delay = 0, gradient = false }: AnimatedTextProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.8, delay }}
      className={`${gradient ? 'text-gradient' : ''} ${className}`}
    >
      {children}
    </motion.div>
  );
}
