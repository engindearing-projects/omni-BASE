import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        omni: {
          // Professional defense tech color palette
          navy: "#0A1628",           // Deep navy primary
          'navy-light': "#162033",   // Lighter navy
          slate: "#1E293B",          // Slate background
          'slate-light': "#334155",  // Lighter slate
          steel: "#475569",          // Steel grey
          accent: "#3B82F6",         // Professional blue accent
          'accent-light': "#60A5FA", // Lighter accent
          teal: "#14B8A6",           // Teal for highlights
          'teal-dark': "#0D9488",    // Darker teal
          olive: "#84CC16",          // Tactical green
          'olive-muted': "#65A30D",  // Muted olive
          white: "#F8FAFC",          // Clean white
          grey: "#94A3B8",           // Neutral grey
          'grey-light': "#CBD5E1",   // Light grey
          'grey-dark': "#64748B",    // Dark grey
          border: "#1E293B",         // Border color
          glow: "#3B82F6",           // Glow color
        },
      },
      fontFamily: {
        sans: ["var(--font-geist-sans)"],
        mono: ["var(--font-geist-mono)"],
      },
      animation: {
        "float": "float 6s ease-in-out infinite",
        "pulse-slow": "pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        "slide-up": "slide-up 0.5s ease-out",
        "fade-in": "fade-in 0.5s ease-out",
        "gradient-x": "gradient-x 15s ease infinite",
        "border-glow": "border-glow 3s ease-in-out infinite",
      },
      keyframes: {
        float: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-10px)" },
        },
        "slide-up": {
          "0%": { transform: "translateY(20px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
        "fade-in": {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        "gradient-x": {
          "0%, 100%": { backgroundPosition: "0% 50%" },
          "50%": { backgroundPosition: "100% 50%" },
        },
        "border-glow": {
          "0%, 100%": { opacity: "0.5" },
          "50%": { opacity: "1" },
        },
      },
      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "gradient-conic": "conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))",
        "hero-pattern": "linear-gradient(to bottom, rgba(10, 22, 40, 0.8), rgba(10, 22, 40, 0.95))",
      },
    },
  },
  plugins: [],
};
export default config;
