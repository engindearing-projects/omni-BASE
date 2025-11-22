# OmniTAK Mobile - Promotional Website

A cutting-edge promotional website for OmniTAK Mobile, built with Next.js 14 and featuring 2028-inspired design aesthetics.

## Features

- ✨ **Futuristic Design**: Glassmorphism, animated particles, and gradient effects
- 🎨 **Advanced Animations**: Framer Motion for smooth, professional animations
- 📱 **Fully Responsive**: Optimized for all devices
- 🔄 **Live Changelog**: Automatically syncs with CHANGELOG.md from the main repo
- 🎯 **Performance Optimized**: Static export for blazing-fast load times
- 🌐 **SEO Ready**: Proper meta tags and semantic HTML

## Tech Stack

- **Next.js 14**: React framework with App Router
- **TypeScript**: Type-safe development
- **Tailwind CSS**: Utility-first styling
- **Framer Motion**: Advanced animations
- **Static Export**: Deployed as static HTML/CSS/JS

## Development

Install dependencies:

```bash
npm install
```

Run development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Build

Build for production:

```bash
npm run build
```

This creates a static export in the `out/` directory.

## Deployment

### Vercel (Recommended)

1. Connect your GitHub repository to Vercel
2. Set the root directory to `website`
3. Vercel will automatically detect Next.js and deploy

Or use the Vercel CLI:

```bash
npm install -g vercel
vercel
```

### Manual Deployment

After building, deploy the contents of the `out/` directory to any static hosting service:

- Netlify
- GitHub Pages
- AWS S3
- Cloudflare Pages
- Any CDN or static host

## Project Structure

```
website/
├── app/
│   ├── api/
│   │   └── changelog/          # API route for changelog
│   ├── layout.tsx              # Root layout
│   ├── page.tsx                # Home page
│   └── globals.css             # Global styles
├── components/
│   ├── AnimatedText.tsx        # Animated text component
│   ├── Changelog.tsx           # Changelog section
│   ├── Download.tsx            # Download section
│   ├── FeatureCard.tsx         # Feature card component
│   ├── Features.tsx            # Features section
│   ├── FloatingParticles.tsx   # Particle animation
│   ├── Footer.tsx              # Footer
│   ├── GlassCard.tsx           # Glass card component
│   ├── GridBackground.tsx      # Grid background
│   ├── Hero.tsx                # Hero section
│   ├── TechStack.tsx           # Tech stack section
│   └── UseCases.tsx            # Use cases section
├── public/                     # Static assets
├── next.config.mjs             # Next.js configuration
├── tailwind.config.ts          # Tailwind configuration
├── tsconfig.json               # TypeScript configuration
└── package.json                # Dependencies
```

## Design System

### Colors

- **Yellow**: `#FFFC00` - Primary brand color
- **Cyan**: `#00FFFF` - Secondary accent
- **Dark**: `#0A0A0A` - Background
- **Gray**: `#1A1A1A` - Secondary background

### Effects

- **Glassmorphism**: Semi-transparent cards with backdrop blur
- **Glow**: Dynamic shadow effects on hover
- **Gradients**: Yellow to cyan gradients for highlights
- **Particles**: Floating animated particles for depth
- **Grid**: Subtle tactical grid background

## Customization

### Updating Colors

Edit `tailwind.config.ts`:

```typescript
colors: {
  omni: {
    yellow: "#FFFC00",
    cyan: "#00FFFF",
    // ...
  },
}
```

### Adding Sections

Create a new component in `components/` and import it in `app/page.tsx`.

### Modifying Animations

Animation parameters are in individual components using Framer Motion's `motion` components.

## Performance

- Static export for instant page loads
- Optimized animations with hardware acceleration
- Lazy loading for images and components
- Minimal JavaScript bundle size

## License

MIT License - Same as the main OmniTAK Mobile project
