'use client';

export default function GridBackground() {
  return (
    <div className="fixed inset-0 z-0 opacity-20">
      <div className="absolute inset-0 mesh-grid" />
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-omni-dark/50 to-omni-dark" />
    </div>
  );
}
