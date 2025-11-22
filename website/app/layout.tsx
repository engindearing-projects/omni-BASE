import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-geist-sans" });

export const metadata: Metadata = {
  title: "OmniTAK Mobile - Professional Tactical Awareness for Mobile",
  description: "Full ATAK-compatible tactical map functionality for iOS and Android. Real-time team coordination, off-grid communication, and mission-critical situational awareness.",
  keywords: ["TAK", "ATAK", "tactical", "military", "first responder", "situational awareness", "mesh networking", "Meshtastic"],
  openGraph: {
    title: "OmniTAK Mobile",
    description: "Professional Tactical Awareness for Mobile",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className={`${inter.variable} font-sans antialiased bg-omni-dark text-omni-light`}>
        {children}
      </body>
    </html>
  );
}
