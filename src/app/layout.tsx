import type { Metadata } from "next";
import "./globals.css";

import { Providers } from "../components/Providers";

export const metadata: Metadata = {
  title: "Nirmaan OS — Industrial Project Intelligence & P6 Schedule Bridge",
  description: "Intelligent Data Capture & Schedule-Linking Layer for Infrastructure & Capital Projects (Oil India Limited SIH26122)",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200"
          rel="stylesheet"
        />
      </head>
      <body className="bg-background text-on-surface font-sans antialiased selection:bg-primary selection:text-on-primary">
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
