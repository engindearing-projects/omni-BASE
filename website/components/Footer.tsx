'use client';

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="relative py-16 px-6 border-t border-omni-border bg-omni-navy/50">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-8 mb-12">
          {/* Brand */}
          <div className="col-span-2">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-omni-accent to-omni-teal flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
                </svg>
              </div>
              <span className="text-xl font-bold text-omni-white">
                Omni<span className="text-omni-accent">TAK</span>
              </span>
            </div>
            <p className="text-sm text-omni-grey max-w-xs">
              Professional tactical awareness for mobile platforms. Real-time team coordination and situational awareness.
            </p>
          </div>

          {/* Product */}
          <div>
            <h4 className="font-semibold text-omni-white mb-4">Product</h4>
            <ul className="space-y-3 text-sm">
              <li><a href="#capabilities" className="text-omni-grey hover:text-omni-accent transition-colors">Capabilities</a></li>
              <li><a href="#features" className="text-omni-grey hover:text-omni-accent transition-colors">Features</a></li>
              <li><a href="#download" className="text-omni-grey hover:text-omni-accent transition-colors">Download</a></li>
              <li><a href="https://github.com/engindearing-projects/omniTAK-mobile/blob/main/apps/omnitak/README.md" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">Documentation</a></li>
            </ul>
          </div>

          {/* Community */}
          <div>
            <h4 className="font-semibold text-omni-white mb-4">Community</h4>
            <ul className="space-y-3 text-sm">
              <li><a href="https://discord.gg/VSUjDddRt3" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">Discord</a></li>
              <li><a href="https://github.com/engindearing-projects/omniTAK-mobile" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">GitHub</a></li>
              <li><a href="https://github.com/engindearing-projects/omniTAK-mobile/issues" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">Issues</a></li>
              <li><a href="https://github.com/engindearing-projects/omniTAK-mobile/blob/main/CONTRIBUTING.md" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">Contributing</a></li>
            </ul>
          </div>

          {/* Developers */}
          <div>
            <h4 className="font-semibold text-omni-white mb-4">Developers</h4>
            <ul className="space-y-3 text-sm">
              <li><a href="https://github.com/engindearing-projects/omniTAK-mobile/blob/main/docs/PLUGIN_DEVELOPMENT_GUIDE.md" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">Plugin Development</a></li>
              <li><a href="https://github.com/engindearing-projects/omniTAK-mobile/blob/main/BUILD_ANDROID.md" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">Build Android</a></li>
              <li><a href="https://github.com/engindearing-projects/omniTAK-mobile/blob/main/DEPENDENCIES.md" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">Dependencies</a></li>
              <li><a href="https://github.com/engindearing-projects/omniTAK-mobile/blob/main/LICENSE" target="_blank" rel="noopener noreferrer" className="text-omni-grey hover:text-omni-accent transition-colors">MIT License</a></li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="border-t border-omni-border pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="text-sm text-omni-grey-dark">
            © {currentYear} OmniTAK Mobile. Open source and MIT licensed.
          </div>
          <div className="flex items-center gap-6 text-sm text-omni-grey-dark">
            <span>Built for tactical professionals worldwide</span>
            <a
              href="https://www.engindearing.soy"
              target="_blank"
              rel="noopener noreferrer"
              className="text-omni-accent hover:text-omni-accent-light transition-colors"
            >
              Engindearing
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
