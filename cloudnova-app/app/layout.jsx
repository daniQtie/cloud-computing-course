import "./globals.css";

export const metadata = {
  title: "CloudNova Technologies — Enterprise Cloud Portal",
  description: "Secure multi-tier infrastructure portal",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
