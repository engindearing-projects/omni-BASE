# Connecting to TAK Server 5.5 - Quick Guide

## Prerequisites

TAK Server 5.5 (official from tak.gov) requires:
- ✅ TLS 1.2 or 1.3 (supported by default)
- ✅ Client certificate authentication (usually required)
- ✅ Self-signed CA (OmniTAK accepts these)

## Method 1: Auto-Discover (Easiest for Local Network)

### Step 1: Find Your Server
```swift
// In your app, present QuickConnectView
let quickConnect = QuickConnectView()

// User selects "Auto-Discover" tab
// Tap "Scan for Servers"
```

This will scan ports: `8087, 8089, 8443, 8444, 8446`

### Step 2: Look for Your Server
You should see something like:
```
📡 Found 2 server(s)
━━━━━━━━━━━━━━━━━━
🔒 TAK Server (SSL)
   192.168.1.100:8089
   [Connect]
```

⚠️ **Note**: Auto-discover won't work without a certificate if the server requires auth. You'll need to enroll first.

## Method 2: Certificate Enrollment (Recommended)

TAK Server 5.5 typically requires client certificates. Here's how to get one:

### Step 1: Get Enrollment Information from Server Admin

Ask your TAK Server administrator for:
1. **Enrollment URL** (or QR code)
2. **Certificate password**

### Step 2: Enroll Using QR Code

If admin provides a QR code:

```swift
// In QuickConnectView
// Select "QR Code" tab
// Tap "Open QR Scanner"
// Scan the QR code
// Enter password when prompted
```

The QR code format is:
```
tak://enroll?server=192.168.1.100&port=8089&truststore=https://...&usercert=https://...
```

### Step 3: Enroll Using Manual URLs

If admin provides URLs directly:

```swift
// In QuickConnectView
// Select "QR Code" tab
// Tap "Manual Entry" at bottom
// Fill in:
```

**Fields:**
- Server Host: `192.168.1.100`
- Port: `8089`
- Trust Store URL: `https://192.168.1.100:8446/Marti/api/tls/config/v2/truststore-root.p12`
- User Cert URL: `https://192.168.1.100:8446/Marti/api/tls/v2/enrollment/user/{username}.p12`
- Password: (from admin)

## Method 3: Manual Certificate Import

If you already have `.p12` certificate files:

### Step 1: Import Certificate

```swift
// Open CertificateManagementView
// Tap "+" → "Import from File"
// Select your .p12 file
// Fill in details:
```

**Fields:**
- Certificate Name: `My TAK Cert`
- Server URL: `https://192.168.1.100`
- Username: `your-username`
- Password: `your-cert-password`

### Step 2: Add Server Configuration

```swift
// Open QuickConnectView
// Select "Manual" tab
// Fill in:
```

**Server Details:**
- Server Name: `TAK Server 5.5`
- Host: `192.168.1.100`
- Port: `8089`
- Use TLS/SSL: ✅ ON
- Certificate: Select the one you just imported

## Method 4: Quick Setup (Preset)

If you want a fast setup:

```swift
// In QuickConnectView
// Select "Quick Setup" tab
// Choose "TAK Server (FreeTAKServer)" or create custom
```

**Modify the preset:**
- Host: `192.168.1.100`
- Port: `8089`
- Certificate Password: (if you have cert)

## Common TAK Server 5.5 Configurations

### Default Ports

| Port | Protocol | Purpose | Certificate Required |
|------|----------|---------|---------------------|
| 8087 | TCP | CoT (plain) | No |
| 8089 | TLS | CoT (encrypted) | **Yes** |
| 8443 | HTTPS | Web UI | No (browser) |
| 8446 | HTTPS | API/Enrollment | Sometimes |

### Typical Setup

**Most common TAK Server 5.5 config:**
```
Protocol: TLS
Port: 8089
TLS Version: 1.2 or 1.3
Certificate: Required (client cert)
CA: Self-signed (TAK Server CA)
```

## Getting Certificate from TAK Server

### Option 1: Ask Admin for QR Code

Best option! Admin runs:
```bash
# On TAK Server
cd /opt/tak
sudo java -jar takserver.war enrollment generate-qr \
  --username your-username \
  --password your-password
```

Admin shows you the QR code → You scan it → Done!

### Option 2: Web Enrollment

1. Open browser: `https://192.168.1.100:8443`
2. Login with admin credentials
3. Go to **Certificate Management**
4. Generate certificate for your username
5. Download `.p12` file
6. Import into OmniTAK

### Option 3: Command Line (Advanced)

If you have SSH access to the server:

```bash
# SSH to TAK Server
ssh user@192.168.1.100

# Generate certificate
cd /opt/tak/certs
sudo ./makeCert.sh client your-username

# Download these files to your iOS device:
# - your-username.p12
# - truststore-root.p12 (or ca.pem)
```

Then import into OmniTAK using CertificateManagementView.

## Troubleshooting

### "Connection Failed"

**Check:**
1. Server is running: `sudo systemctl status takserver`
2. Firewall allows port 8089: `sudo ufw status`
3. You're on the same network
4. Server IP is correct

### "SSL Handshake Failed"

**Solutions:**
- Ensure TLS is enabled in OmniTAK (useTLS: true)
- Check certificate is valid
- Verify certificate password is correct
- Make sure certificate matches the server

### "Certificate Required"

**Fix:**
- You need to enroll and get a client certificate
- TAK Server 5.5 requires certificates by default
- Follow enrollment steps above

### "Certificate Expired"

**Fix:**
```bash
# On TAK Server, check cert validity
cd /opt/tak/certs
openssl pkcs12 -in your-username.p12 -nokeys -passin pass:atakatak | \
  openssl x509 -noout -dates
```

Generate new certificate if expired.

## Testing Connection

### Step 1: Check Server is Accessible

```bash
# From your Mac/iOS device network
ping 192.168.1.100

# Test TLS port
nc -zv 192.168.1.100 8089
```

### Step 2: Test with OpenSSL

```bash
# Test TLS connection
openssl s_client -connect 192.168.1.100:8089 -tls1_2

# Test with client cert (if you have it)
openssl s_client -connect 192.168.1.100:8089 \
  -cert your-cert.pem -key your-key.pem
```

### Step 3: Connect in OmniTAK

Watch debug console for:
```
🔒 Using TLS/SSL (TLS 1.2-1.3, legacy cipher suites enabled, accepting self-signed certs)
🔐 Configuring client certificate: your-cert
✅ Client certificate loaded successfully
✅ DirectTLS: Connected to 192.168.1.100:8089
```

## Quick Reference

### Minimum Info Needed

To connect to TAK Server 5.5, you need:
- ✅ Server IP: `192.168.1.100` (example)
- ✅ Port: `8089` (typical)
- ✅ Client Certificate: `.p12` file
- ✅ Certificate Password: `atakatak` (or custom)

### Fastest Methods Ranked

1. **QR Code Scan** (30 sec) - If admin provides QR
2. **Auto-Discover** (1 min) - If no cert required
3. **Quick Setup** (2 min) - If you have cert already
4. **Manual Entry** (3 min) - Full control

## Example Connection Flow

```
1. Open OmniTAK
2. Go to Settings → Connect to Server
3. QuickConnectView opens
4. Select "QR Code" tab
5. Tap "Open QR Scanner"
6. Scan QR from TAK Server admin
7. Enter password (from admin)
8. Wait for enrollment (15 sec)
9. ✅ Success! Connected to TAK Server
10. See green "Connected" status
11. Start sharing position data
```

## Need Help?

### Get Server Info

Ask your TAK Server admin for:
```
Server IP: _______________
Port: _______________
Enrollment URL or QR: _______________
Certificate Password: _______________
```

### Check OmniTAK Logs

In Xcode debug console, look for:
```
🌐 Using explicit IPv4: 192.168.1.100
🔒 Using TLS/SSL (TLS 1.2-1.3...)
🔓 Accepting server certificate (self-signed CA)
🔐 Configuring client certificate: ...
✅ Client certificate loaded successfully
✅ DirectTLS: Connected to 192.168.1.100:8089
```

### Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Can't find server | Check IP, check network |
| SSL error | Enable TLS, check cert |
| Certificate invalid | Re-enroll, check password |
| Connection timeout | Check firewall, check server running |
| Auth failed | Check username/password |

---

**You're ready to connect!** 🚀

TAK Server 5.5 is fully supported with TLS 1.2/1.3 and client certificate authentication.
