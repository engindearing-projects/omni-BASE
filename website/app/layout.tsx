import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-geist-sans" });

export const metadata: Metadata = {
  title: "OmniTAK Mobile - Professional Tactical Awareness for Mobile",
  description: "Full ATAK-compatible tactical map functionality for iOS and Android. Real-time team coordination, off-grid communication, and mission-critical situational awareness.",
  keywords: ["TAK", "ATAK", "tactical", "military", "first responder", "situational awareness", "mesh networking", "Meshtastic"],
  icons: {
    icon: [
      { url: '/favicon.ico' },
      { url: '/favicon-16x16.png', sizes: '16x16', type: 'image/png' },
      { url: '/favicon-32x32.png', sizes: '32x32', type: 'image/png' },
      { url: '/favicon-120x120.png', sizes: '120x120', type: 'image/png' },
      { url: '/favicon-152x152.png', sizes: '152x152', type: 'image/png' },
      { url: '/favicon-180x180.png', sizes: '180x180', type: 'image/png' },
    ],
    apple: [
      { url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' },
    ],
  },
  openGraph: {
    title: "OmniTAK Mobile",
    description: "Professional Tactical Awareness for Mobile",
    type: "website",
    images: [
      {
        url: '/logo.png',
        width: 1024,
        height: 1024,
        alt: 'OmniTAK Mobile Logo',
      },
    ],
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
