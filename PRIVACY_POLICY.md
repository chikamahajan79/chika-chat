# Privacy Policy for Chika

**Last Updated:** November 13, 2026  
**Developer Contact:** chetan@chetan.co  
**Application:** Chika (com.chetan.chika)

---

## 1. Introduction
Chika is built from the ground up with zero-knowledge, end-to-end encryption. Our philosophy is simple: we believe your personal communications and media are exclusively yours. We do not collect, monetize, sell, or inspect your personal communications.

## 2. Information We Do NOT Collect
- **No Phone Numbers or Real Names Required:** Chika uses anonymous cryptographic keys and random identifiers paired via QR codes.
- **No Message Plaintext:** All messages, photos, videos, and voice notes are end-to-end encrypted on your device using the Signal Protocol (Double Ratchet + X3DH) and AES-256-GCM before transmission.
- **No Decryption Keys:** The encryption keys are generated and stored exclusively on your device within the hardware-backed Android Keystore / iOS Keychain.

## 3. Ephemeral Server Data & Retention
- **In-Transit Ciphertext:** When sending an encrypted message or media blob to an offline user, our servers temporarily queue the unreadable ciphertext.
- **Immediate Automated Deletion:** As soon as the recipient device receives the ciphertext and delivers an acknowledgment receipt (ACK), the envelope is **permanently purged** from our server memory and databases.
- **Biometric Security:** Biometric authentication (fingerprint/facial recognition) is processed entirely locally on your device via the operating system's secure biometric framework. We never have access to your biometric samples.

## 4. Third-Party Services
- **Push Notifications (Optional):** We send silent or generic notifications (with zero message text and zero sender information) to alert your device to sync in the background.

## 5. Contact Us
If you have any questions or concerns regarding this Privacy Policy, please contact:  
**Email:** chetan@chetan.co
