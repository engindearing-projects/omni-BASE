# OmniTAKMobile - iOS Tactical Awareness App

Full-featured native iOS tactical awareness app with ATAK-style interface, CoT messaging, map visualization, and drawing tools.

---

## 🚀 Complete Beginner's Guide

**Never built an iOS app before? Start here!**

This guide will walk you through every step with no prior iOS development experience required.

### Step 0: Verify Your Mac

First, check if you meet the requirements:

```bash
# Check macOS version (should be 12.0+)
sw_vers

# Expected output:
# ProductName:        macOS
# ProductVersion:     14.x.x  (or 13.x, 12.x)
# BuildVersion:       ...
```

If your macOS version is less than 12.0, you'll need to upgrade your Mac first.

---

## Prerequisites Setup

### 1. Install Xcode (Required - ~15 minutes)

**Option A: Mac App Store (Easiest)**
1. Open **App Store** on your Mac
2. Search for **"Xcode"**
3. Click **"Get"** or **"Install"** (it's free)
4. Wait 10-15 minutes for ~13 GB download
5. Once installed, open Xcode
6. Click **"Install"** when prompted for additional components
7. Accept the license agreement

**Option B: Direct Download**
1. Visit [developer.apple.com/xcode](https://developer.apple.com/xcode/)
2. Download the latest Xcode
3. Drag Xcode to your Applications folder

**Verify Xcode Installation:**
```bash
# Check Xcode version
xcodebuild -version

# Expected output:
# Xcode 15.x
# Build version ...
```

✅ **If you see version 15.0 or higher, you're good!**
❌ **If command not found:** Xcode isn't installed properly

### 2. Install Command Line Tools (Required - ~5 minutes)

```bash
# Install command line tools
xcode-select --install
```

A popup will appear:
1. Click **"Install"**
2. Click **"Agree"** to license
3. Wait 3-5 minutes for installation

**Verify Installation:**
```bash
# Check if tools are installed
xcode-select -p

# Expected output:
# /Applications/Xcode.app/Contents/Developer
```

✅ **If you see the path above, you're good!**
❌ **If error:** Run `sudo xcode-select --reset` and try again

### 3. Install Git (Usually Pre-installed - ~1 minute)

```bash
# Check if Git is installed
git --version

# Expected output:
# git version 2.x.x
```

✅ **If you see a version number, you're good!**
❌ **If command not found:** Install from [git-scm.com](https://git-scm.com/download/mac)

### 4. Apple ID Setup (Free - ~2 minutes)

**You need an Apple ID to run apps on devices (even your own iPhone).**

If you don't have one:
1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Click **"Create Your Apple ID"**
3. Follow the prompts (it's free!)

**Add Apple ID to Xcode:**
1. Open **Xcode**
2. Go to **Xcode** menu → **Settings** (or **Preferences** in older versions)
3. Click **"Accounts"** tab
4. Click **"+"** at bottom-left
5. Select **"Apple ID"**
6. Enter your Apple ID and password
7. Click **"Next"**

✅ **You should see your Apple ID listed with a "Personal Team"**

---

## 📦 Clone and Build the Project

### Step 1: Clone the Repository

Open **Terminal** (Applications → Utilities → Terminal) and run:

```bash
# Navigate to a folder where you want to download the project
cd ~/Desktop  # or any folder you prefer

# Clone the repository
git clone https://github.com/your-username/omni-BASE.git

# Navigate to the project
cd omni-BASE/apps/omnitak

# Verify you're in the right place
ls -la
```

**Expected output should include:**
```
OmniTAKMobile.xcodeproj      <- This is the Xcode project file
OmniTAKMobile/               <- This folder contains all the code
README.md                    <- This file
...
```

✅ **If you see `OmniTAKMobile.xcodeproj`, you're in the right place!**
❌ **If not found:** You may be in the wrong directory. Run `pwd` to see where you are.

### Step 2: Open in Xcode and Build for Simulator

**This is the easiest way to test - no iPhone needed!**

```bash
# Open the project in Xcode (from Terminal)
open OmniTAKMobile.xcodeproj
```

**Xcode should open with the project loaded.**

#### Configure Simulator (One-Time Setup)

1. **At the top-left of Xcode**, you'll see a device dropdown next to "OmniTAKMobile"
2. Click the device dropdown
3. You'll see a list like:
   ```
   iPhone 16 Pro
   iPhone 16
   iPhone 15 Pro
   iPad Pro
   ...
   ```
4. **Select any iPhone simulator** (e.g., "iPhone 16 Pro")

✅ **The dropdown should now show:** `OmniTAKMobile > iPhone 16 Pro`

#### Build and Run

**Method 1: Using Xcode GUI (Recommended)**

1. Click the **▶ Play button** at top-left (or press `⌘ + R`)
2. Watch the build progress bar at the top
3. **First build takes 2-5 minutes** - be patient!
4. You'll see messages like:
   ```
   Building...
   Compiling MapViewController.swift
   Linking...
   Build Succeeded
   ```
5. The iOS Simulator will launch automatically
6. The OmniTAKMobile app will open showing a map

**Method 2: Using Terminal (Advanced)**

```bash
# Build the app
xcodebuild -scheme OmniTAKMobile \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# Look for this at the end:
# ** BUILD SUCCEEDED **
```

#### What You Should See

After the app launches in the simulator:
- 📱 An iOS device window appears (looks like a real iPhone)
- 🗺️ A satellite map view (centered on Washington DC by default)
- 📊 Status bar at top showing "OmniTAK" and connection status
- 🎯 Bottom toolbar with GPS, zoom, draw buttons
- 🔴 "DISC" (disconnected) indicator - this is normal (no server configured yet)

**Simulator Limitations:**
- ❌ GPS location is simulated (doesn't use real location)
- ❌ Can't connect to real TAK servers without network configuration
- ✅ All UI features work perfectly
- ✅ Drawing, maps, and offline features work

---

### Step 3: Build for Physical iPhone/iPad (Optional)

**Want to test on your actual iPhone? Follow these steps.**

#### A. Configure Code Signing (One-Time - ~3 minutes)

**Why do I need this?** Apple requires all apps to be signed, even for testing on your own device.

1. **In Xcode, look at the left sidebar**
   - You should see a blue **OmniTAKMobile** icon at the top
   - Click on it

2. **Select the Target**
   - In the main editor area, you'll see "TARGETS" list
   - Click **"OmniTAKMobile"** under TARGETS

3. **Go to Signing & Capabilities tab**
   - At the top of the editor, click **"Signing & Capabilities"**

4. **Configure Automatic Signing**
   - Find the checkbox **"Automatically manage signing"**
   - ✅ **Check this box**
   - Under "Team", click the dropdown
   - Select your **Apple ID** (it should say "Personal Team")

5. **Change Bundle Identifier (if error appears)**
   - If you see a red error like "Failed to register bundle identifier"
   - Change the **Bundle Identifier** from `com.omnitak.mobile` to something unique like:
     ```
     com.yourname.omnitak.mobile
     ```
   - Replace `yourname` with your actual name or any unique text

✅ **Success looks like:**
- No red errors in the Signing section
- You see "Signing Certificate: Apple Development: your@email.com"
- Bundle Identifier is unique

❌ **Common errors:**
- "Failed to create provisioning profile" → Your Apple ID isn't added to Xcode (see Prerequisites Step 4)
- "Bundle identifier already in use" → Change the bundle ID to something unique

#### B. Connect Your iPhone/iPad

1. **Connect your device to your Mac**
   - Use a USB-C or Lightning cable
   - **Must be a data cable** (not just charging cable)

2. **Unlock your iPhone/iPad**

3. **Trust This Computer popup**
   - On your iPhone/iPad, you'll see: "Trust This Computer?"
   - Tap **"Trust"**
   - Enter your device passcode

4. **Enable Developer Mode** (iOS 16+ only)
   - On your iPhone/iPad: **Settings** → **Privacy & Security** → **Developer Mode**
   - Toggle **Developer Mode** to **ON**
   - Tap **"Restart"** when prompted
   - After restart, tap **"Turn On"** to confirm

**Verify device is connected:**
```bash
# In Terminal, run:
xcrun xctrace list devices

# You should see your device listed, like:
# John's iPhone (16.0) (00008030-XXXXXXXXXXXX)
```

#### C. Build and Install to Your Device

**In Xcode:**

1. **Select Your Device**
   - At the top-left, click the device dropdown (currently showing "iPhone 16 Pro")
   - Under **"iOS Device"** section, select **your connected iPhone**
   - It will show the device name (e.g., "John's iPhone")

2. **Build and Run**
   - Click the **▶ Play button** (or press `⌘ + R`)
   - **First build on device takes 3-7 minutes**
   - You'll see build progress at the top

3. **Watch for Build Success**
   ```
   Build Succeeded
   Running OmniTAKMobile on John's iPhone
   ```

#### D. Trust the App (First Install Only - ~1 minute)

**The app will install but won't open yet. You need to trust it first.**

1. **On your iPhone/iPad:**
   - Go to **Settings** → **General** → **VPN & Device Management**
   - You'll see your Apple ID under **"DEVELOPER APP"**
   - Tap on **your Apple ID**

2. **Trust the Developer**
   - Tap **"Trust [Your Apple ID]"**
   - Tap **"Trust"** again in the popup

3. **Launch the App**
   - Go to your home screen
   - Find and tap **OmniTAKMobile** icon
   - The app should launch successfully! 🎉

#### What You Should See on Your Device

- 🗺️ Satellite map view of your current location (GPS works!)
- 📊 Compact translucent status bar at top
- 🎯 Bottom toolbar with GPS, zoom, draw buttons
- 📍 Your real GPS location shown as a blue dot
- 🔴 "DISC" indicator (normal - no server configured yet)

**Device Benefits:**
- ✅ Real GPS location tracking
- ✅ Full performance (faster than simulator)
- ✅ Test all sensors (compass, accelerometer)
- ✅ Real network connectivity

## First Launch - Configure TAK Server

1. **Launch OmniTAKMobile** on your device/simulator

2. **Open Server Configuration**:
   - Tap the **hamburger menu** (≡) in the top-right
   - Select **"Servers"** or tap the server status in the status bar

3. **Add TAK Server**:
   - **Server Name**: "My TAK Server" (or any name)
   - **Host**: Your TAK server IP or hostname
   - **Port**: `8087` (typical TAK server port)
   - **Protocol**: TCP, TLS, or WebSocket
   - Tap **"Save"** then **"Connect"**

4. **Monitor Connection**:
   - Status bar shows connection state
   - Green = Connected, Red = Disconnected
   - Message counters update as CoT messages flow

5. **Start Using the App**:
   - Your GPS location broadcasts automatically
   - Long-press on map to access radial menu
   - Use bottom toolbar for quick actions
   - Access drawing tools from right side

## App Features

### 🗺️ Map & Navigation
- **Multi-layer maps**: Satellite, Hybrid, Standard
- **MGRS Grid overlay** with configurable density
- **GPS tracking** with bearing and accuracy
- **Compass overlay** and coordinate display
- **Zoom controls** and gesture navigation

### 📡 TAK Server Integration
- **Multi-server support**: Connect to multiple TAK servers
- **CoT messaging**: Send/receive Cursor-on-Target messages
- **Position broadcasting**: Automatic self-SA updates
- **SSL/TLS support**: Secure connections with certificates
- **Federation support**: Multi-server message routing

### ✏️ Drawing & Annotations
- **Drawing tools**: Lines, polygons, circles, markers
- **Color customization**: Choose colors for each drawing
- **Persistent storage**: Drawings saved locally
- **CoT generation**: Drawings broadcast as CoT messages
- **Edit/delete**: Manage drawings with radial menu

### 💬 Communications
- **Chat system**: Send messages to teams/individuals
- **Team management**: Create and manage tactical teams
- **Contact list**: View connected units
- **Emergency beacon**: Send 911/SOS alerts

### 📊 Tactical Tools
- **Geofencing**: Create zones with entry/exit alerts
- **Route planning**: Plan and navigate routes
- **Range & Bearing**: Measure distances and bearings
- **Elevation profiles**: View terrain elevation
- **Line of Sight**: Calculate visibility between points

### 🎯 Advanced Features
- **Waypoint navigation**: Create and navigate to waypoints
- **Track recording**: Record movement breadcrumbs
- **Mission packages**: Share data packages
- **Plugin system**: Extensible architecture
- **Offline maps**: Download maps for offline use

---

## 🔧 Troubleshooting

**Having issues? Find your problem below and follow the exact steps to fix it.**

### Common Build Errors

#### ❌ "No such module 'SwiftUI'" or "Cannot find type 'View'"

**Problem:** Xcode is using the wrong Swift version or toolchain.

**Solution:**
1. Quit Xcode completely (`⌘ + Q`)
2. Open Terminal and run:
   ```bash
   sudo xcode-select --reset
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
3. Reopen Xcode and rebuild

---

#### ❌ "Code signing error" / "No signing certificate"

**Problem:** You haven't configured your Apple ID or bundle identifier.

**Solution (Step-by-step):**
1. Open Xcode → **Xcode menu** → **Settings** → **Accounts**
2. If your Apple ID isn't listed:
   - Click **"+"** button
   - Add your Apple ID
   - Wait for it to load
3. In your project:
   - Select **OmniTAKMobile** (blue icon) in left sidebar
   - Select **OmniTAKMobile** under TARGETS
   - Click **Signing & Capabilities** tab
   - ✅ Check **"Automatically manage signing"**
   - Select your Team (your Apple ID)
4. If you still see errors:
   - Change **Bundle Identifier** to: `com.YOURNAME.omnitak`
   - Replace `YOURNAME` with your actual name (no spaces)

---

#### ❌ "Sandbox: rsync.samba deny(1) file-write-create"

**Problem:** macOS security blocking build files.

**Solution:**
1. Open **System Settings** (or System Preferences)
2. Go to **Privacy & Security**
3. Scroll down to **Developer Tools**
4. Make sure **Terminal** and **Xcode** are allowed
5. If not listed, try rebuilding - macOS will prompt you to allow

---

#### ❌ Build takes forever or freezes at "Compiling..."

**Problem:** Xcode indexes or derived data corruption.

**Solution (try in order):**
1. **Clean Build Folder:**
   - Xcode menu → **Product** → **Clean Build Folder** (`Shift + ⌘ + K`)
   - Wait for it to finish
   - Try building again

2. **Clear Derived Data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```
   - Reopen Xcode
   - Rebuild (first build will take longer)

3. **Restart Xcode:**
   - Quit Xcode (`⌘ + Q`)
   - Reopen project
   - Try again

---

#### ❌ "The app installation failed" / "Unable to install..."

**Problem:** Old version of app still installed or device storage full.

**Solution:**
1. **Delete old app from device:**
   - On iPhone: Long-press app icon → **Remove App** → **Delete App**
   - On Simulator: Long-press app icon → **Delete App**

2. **Check device storage:**
   - Settings → General → iPhone Storage
   - Make sure you have at least 1 GB free

3. **Restart device:**
   - Turn iPhone off and on
   - Try installing again

---

### Common Device Issues

#### ❌ "iPhone not showing in device dropdown"

**Problem:** Device not recognized by Xcode.

**Solution (try each step):**
1. **Unplug and replug cable** (try different USB port)
2. **Unlock iPhone** (device must be unlocked)
3. **Trust computer:**
   - On iPhone: Tap "Trust" when prompted
   - Enter passcode
4. **Restart Xcode:**
   - Quit and reopen Xcode
   - Wait 10 seconds for device to appear
5. **Check cable:**
   - Make sure you're using a data cable (not charge-only)
   - Try a different cable if available

---

#### ❌ "Developer Mode Required" (iOS 16+)

**Problem:** Developer Mode is not enabled on your device.

**Solution:**
1. On your iPhone: **Settings** → **Privacy & Security** → **Developer Mode**
2. Toggle **ON**
3. Tap **"Restart"**
4. After restart, tap **"Turn On"** to confirm
5. Try installing app again

---

#### ❌ "Untrusted Developer" / App won't open

**Problem:** You haven't trusted your developer certificate.

**Solution:**
1. On iPhone: **Settings** → **General** → **VPN & Device Management**
2. Under **DEVELOPER APP**, tap your Apple ID
3. Tap **"Trust [Your Apple ID]"**
4. Tap **"Trust"** again
5. Go back to home screen
6. Tap app icon - it should open now

---

### Simulator Issues

#### ❌ Simulator is slow or laggy

**Problem:** Simulator using too many resources.

**Solution:**
1. **Use smaller device:** iPhone SE instead of iPhone 16 Pro Max
2. **Close other apps** on your Mac
3. **Reduce graphics quality:**
   - Simulator menu → **Window** → **Show Device Bezels** (turn OFF)
4. **Restart simulator:**
   - Device menu → **Restart**

---

#### ❌ Simulator shows black screen

**Problem:** Simulator crashed or didn't load properly.

**Solution:**
1. **Simulator menu** → **Device** → **Erase All Content and Settings**
2. Confirm erasure
3. Rebuild and run app
4. If still black, quit Simulator and Xcode, then reopen

---

### Runtime Issues

#### ❌ App crashes immediately on launch

**Problem:** Could be several things.

**Solution (try in order):**
1. **Check Xcode Console for crash log:**
   - Look at bottom panel in Xcode after crash
   - Search for "Error" or "Fatal"
   - If you see "signal SIGKILL", device is low on memory

2. **Check iOS version compatibility:**
   - Project requires iOS 15.0+
   - On iPhone: **Settings** → **General** → **About** → **iOS Version**
   - Must be 15.0 or higher

3. **Clean reinstall:**
   - Delete app from device/simulator
   - Clean build folder (Shift + ⌘ + K)
   - Rebuild and reinstall

---

#### ❌ GPS location not working (Simulator)

**This is normal!** Simulators use a fake location by default.

**Set custom location:**
1. Simulator menu → **Features** → **Location** → **Custom Location**
2. Enter coordinates (e.g., Washington DC: 38.8977, -77.0365)
3. App will show this location

**For real GPS:** Use a physical iPhone/iPad instead.

---

#### ❌ Map shows blank/white screen

**Problem:** Network issue or map tiles not loading.

**Solution:**
1. **Check internet connection**
2. **Change map type:**
   - Long-press on map → **Layers** → Try "Satellite" or "Hybrid"
3. **Restart app**

---

### Still Having Issues?

If none of the above helped:

1. **Check Xcode version:**
   ```bash
   xcodebuild -version
   # Should be 15.0 or higher
   ```

2. **Update Xcode:**
   - App Store → **Updates** → Update Xcode
   - Restart Mac after update

3. **Create issue on GitHub:**
   - Include exact error message
   - Include Xcode version
   - Include macOS version
   - Include steps you tried

## Advanced Configuration

### Custom Certificate Setup (TLS/SSL)

For secure TAK server connections:

1. **Export your server certificate** (.p12 or .pfx format)
2. **Add to Xcode project**:
   - Drag certificate into project navigator
   - Check "Copy items if needed"
   - Add to OmniTAKMobile target
3. **Configure in app**:
   - Settings → Certificates → Import
   - Enter certificate password
   - Select for TAK server connection

### Building Release Version

For App Store or TestFlight distribution:

```bash
# Build archive
xcodebuild archive \
  -scheme OmniTAKMobile \
  -configuration Release \
  -archivePath ./build/OmniTAKMobile.xcarchive

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/OmniTAKMobile.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions-Development.plist
```

## Architecture

### Application Stack

```
┌─────────────────────────────────────────┐
│   SwiftUI Views (UI Layer)              │
│   - MapViewController                   │
│   - Drawing Tools                       │
│   - Chat Interface                      │
│   - Settings Panels                     │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│   Coordinators & Services               │
│   - TAKService (CoT messaging)          │
│   - DrawingManager                      │
│   - LocationManager                     │
│   - ChatManager                         │
│   - Federation (multi-server)           │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│   Map Integration                       │
│   - MapKit (Apple Maps)                 │
│   - Custom Overlays (MGRS, drawings)    │
│   - Annotations (markers, units)        │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│   Data Layer                            │
│   - SwiftData/CoreData persistence      │
│   - UserDefaults (preferences)          │
│   - File storage (certificates, maps)  │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│   Rust Core (XCFramework)               │
│   - omnitak_mobile FFI                  │
│   - Network protocols                   │
│   - CoT parsing/generation              │
└─────────────────────────────────────────┘
              ↓
        TAK Server
    (TCP/TLS/WebSocket)
```

### Key Components

- **MapViewController**: Main ATAK-style tactical map view
- **TAKService**: Manages CoT connections and message routing
- **DrawingManager**: Handles tactical drawing and annotations
- **RadialMenuCoordinator**: Context-sensitive radial menus
- **MultiServerFederation**: Multi-server connection management
- **LocationManager**: GPS tracking and position broadcasting

### Data Flow

1. **User Action** → UI Event → Coordinator
2. **Coordinator** → Service Layer → Data Processing
3. **Service** → Rust FFI → Network/Protocol
4. **Network** → TAK Server → CoT Messages
5. **CoT Received** → Parse → Update UI

## Project Structure

```
OmniTAKMobile/
├── OmniTAKMobile.xcodeproj     # Xcode project
├── OmniTAKMobile/              # Source code
│   ├── MapViewController.swift # Main map view
│   ├── TAKService.swift        # TAK server integration
│   ├── DrawingTools*.swift     # Drawing system
│   ├── Chat*.swift             # Chat system
│   ├── Team*.swift             # Team management
│   ├── Route*.swift            # Route planning
│   ├── Geofence*.swift         # Geofencing
│   ├── RadialMenu*.swift       # Radial menus
│   └── ...                     # Other features
├── OmniTAKMobile.xcframework/  # Rust core library
├── Assets.xcassets/            # Images and icons
├── Info.plist                  # App configuration
└── README.md                   # This file
```

## Development

### Running Tests

```bash
# Run all tests
xcodebuild test \
  -scheme OmniTAKMobile \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run specific test
xcodebuild test \
  -scheme OmniTAKMobile \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:OmniTAKMobileTests/TAKServiceTests
```

### Debugging

**Enable verbose logging:**
```swift
// In AppDelegate or main app file
#if DEBUG
print("🐛 Debug mode enabled")
// Enable detailed TAK protocol logging
TAKService.debugMode = true
#endif
```

**View device logs in Xcode:**
1. Window → Devices and Simulators
2. Select your device
3. Click "Open Console" button
4. Filter by "OmniTAKMobile"

**Network debugging:**
```bash
# Monitor network traffic (requires physical device)
rvictl -s <device-udid>
sudo tcpdump -i rvi0 -n -s 0 -w omnitak.pcap
# Open omnitak.pcap in Wireshark
```

### Code Style

- **SwiftUI** for UI components
- **MVVM** architecture pattern
- **Observable Objects** for state management
- **Swift Concurrency** (async/await) for networking
- **SwiftData** for persistence

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/my-feature`
5. Submit a Pull Request

## License

[Specify your license here]

## Support

For issues, questions, or contributions:
- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)
- **Documentation**: [Wiki](https://github.com/your-repo/wiki)

## Credits

Built with:
- **Swift** and **SwiftUI**
- **MapKit** for mapping
- **Rust** core library for TAK protocol
- Inspired by **ATAK** (Android Team Awareness Kit)

---

**Note**: This app is for educational and tactical awareness purposes. Ensure you have proper authorization before connecting to production TAK servers.
