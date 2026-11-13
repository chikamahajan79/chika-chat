# E2EE WhatsApp Replica (Zero-Knowledge Architecture)

A privacy-centric WhatsApp replica with hardware-backed biometric security, anonymous QR pairing, Signal Protocol End-to-End Encryption, and zero-knowledge ephemeral relays.

---

## 📁 Repository Structure

```
e2ee-chat-app/
├── app/                                # Flutter Mobile Client
│   ├── lib/
│   │   ├── services/
│   │   │   ├── biometric_auth_service.dart   # Biometric Gate & Hardware Keystore
│   │   │   └── media_cipher_service.dart     # Client-Side AES-256-GCM Media Crypto
│   │   └── ...
│   └── pubspec.yaml                    # Flutter dependencies (Signal, Crypto, Biometrics)
└── server/                             # Zero-Knowledge Ephemeral Relay
    ├── server.js                       # WebSocket Router, Pre-Key Registry & Media Vault
    └── package.json
```

---

## 🚀 Getting Started

### 1. Prerequisites
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK `>= 3.0.0`)
- **Node.js**: [Install Node.js](https://nodejs.org/) (`>= 18.0.0`)
- **Android Studio / Xcode** with an emulator or physical mobile device.

---

### 2. Running the Ephemeral Server
```bash
cd server
npm install
npm start
```
The server will start on `http://localhost:4000` and `ws://localhost:4000`.

---

### 3. Running the Flutter Mobile App
```bash
cd app
flutter pub get
flutter run
```

---

## 🔒 Security & Privacy Highlights
1. **Biometric App Lock**: Secured with `local_auth` and hardware Keychain/Keystore policies.
2. **Anonymous Pairing**: No phone numbers or emails required; pairs directly via QR code / Public Key exchange.
3. **End-to-End Encryption**: Signal Protocol (Double Ratchet + X3DH) with forward and future secrecy.
4. **Zero-Knowledge Media**: Files are encrypted with random AES-256-GCM keys on-device before uploading to the server.
5. **Instant Server Purge**: Offline message envelopes are stored only until delivered, then permanently purged upon receipt ACK.
6. **Zero-Metadata Push**: Silent push notifications with no message text or sender metadata.
