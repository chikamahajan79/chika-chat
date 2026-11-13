/**
 * Zero-Knowledge Ephemeral Signaling & Media Server
 * 
 * Guarantees:
 * 1. Messages are encrypted payloads forwarded in real-time.
 * 2. If the recipient is offline, encrypted envelopes are stored in RAM/temp queue.
 * 3. Immediately upon receiving recipient ACK, the message envelope is purged.
 * 4. Media blobs are uploaded as raw ciphertext. The server has no decryption keys.
 */

const express = require('express');
const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// Ephemeral In-Memory Stores (can be backed by Redis in production)
const clients = new Map(); // userId -> WebSocket connection
const preKeyStore = new Map(); // userId -> PreKey bundle
const offlineEnvelopes = new Map(); // recipientId -> Array of encrypted envelopes

// Setup Encrypted Media upload directory
const UPLOAD_DIR = path.join(__dirname, 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => cb(null, `${uuidv4()}_blob.enc`)
});
const upload = multer({ storage, limits: { fileSize: 50 * 1024 * 1024 } }); // 50MB max

// ---------------- REST API ----------------

// Register or update Pre-Key Bundle (X3DH Handshake data)
app.post('/api/keys/register', (req, res) => {
  const { userId, identityKey, signedPreKey, oneTimePreKeys, signature } = req.body;
  if (!userId || !identityKey) {
    return res.status(400).json({ error: 'Missing required key bundle parameters' });
  }

  preKeyStore.set(userId, {
    identityKey,
    signedPreKey,
    oneTimePreKeys: oneTimePreKeys || [],
    signature,
    updatedAt: Date.now()
  });

  return res.json({ success: true, message: 'Pre-key bundle registered successfully' });
});

// Fetch recipient Pre-Key Bundle for initiating a Double Ratchet session
app.get('/api/keys/:userId', (req, res) => {
  const bundle = preKeyStore.get(req.params.userId);
  if (!bundle) {
    return res.status(404).json({ error: 'User pre-key bundle not found' });
  }

  // Pop a one-time pre-key if available to preserve forward secrecy
  let oneTimeKey = null;
  if (bundle.oneTimePreKeys && bundle.oneTimePreKeys.length > 0) {
    oneTimeKey = bundle.oneTimePreKeys.shift();
  }

  return res.json({
    userId: req.params.userId,
    identityKey: bundle.identityKey,
    signedPreKey: bundle.signedPreKey,
    signature: bundle.signature,
    oneTimePreKey: oneTimeKey
  });
});

// Upload ciphertext media blob (Zero-Knowledge)
app.post('/api/media/upload', upload.single('media'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No ciphertext file uploaded' });
  }

  return res.json({
    success: true,
    fileId: req.file.filename,
    downloadUrl: `/api/media/${req.file.filename}`,
    size: req.file.size
  });
});

// Download ciphertext media blob
app.get('/api/media/:fileId', (req, res) => {
  const filePath = path.join(UPLOAD_DIR, req.params.fileId);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'Ciphertext media not found or already purged' });
  }
  res.sendFile(filePath);
});

// ---------------- WebSocket Ephemeral Relay ----------------

wss.on('connection', (ws, req) => {
  let authenticatedUserId = null;

  ws.on('message', (messageRaw) => {
    try {
      const msg = JSON.parse(messageRaw);

      switch (msg.type) {
        // 1. Authenticate WebSocket session
        case 'AUTH': {
          authenticatedUserId = msg.userId;
          clients.set(authenticatedUserId, ws);
          console.log(`[WS] User connected: ${authenticatedUserId}`);

          // Flush pending offline envelopes
          if (offlineEnvelopes.has(authenticatedUserId)) {
            const pending = offlineEnvelopes.get(authenticatedUserId);
            for (const env of pending) {
              ws.send(JSON.stringify({ type: 'ENCRYPTED_MESSAGE', envelope: env }));
            }
          }
          break;
        }

        // 2. Relay Encrypted Envelope
        case 'SEND_MESSAGE': {
          const { recipientId, envelope } = msg;
          const envelopeWithMeta = {
            id: envelope.id || uuidv4(),
            senderId: authenticatedUserId,
            recipientId,
            cipherPayload: envelope.cipherPayload,
            timestamp: Date.now()
          };

          const recipientWs = clients.get(recipientId);
          if (recipientWs && recipientWs.readyState === WebSocket.OPEN) {
            recipientWs.send(JSON.stringify({
              type: 'ENCRYPTED_MESSAGE',
              envelope: envelopeWithMeta
            }));
          } else {
            // Store ephemerally until recipient comes online
            if (!offlineEnvelopes.has(recipientId)) {
              offlineEnvelopes.set(recipientId, []);
            }
            offlineEnvelopes.get(recipientId).push(envelopeWithMeta);
            console.log(`[WS] Stored offline envelope for: ${recipientId}`);
          }

          // Acknowledge receipt to sender
          ws.send(JSON.stringify({
            type: 'MESSAGE_SENT_ACK',
            messageId: envelopeWithMeta.id,
            recipientId
          }));
          break;
        }

        // 3. Purge Envelope upon Recipient Delivery ACK
        case 'DELIVERY_ACK': {
          const { messageId } = msg;
          if (authenticatedUserId && offlineEnvelopes.has(authenticatedUserId)) {
            const list = offlineEnvelopes.get(authenticatedUserId);
            const updated = list.filter((env) => env.id !== messageId);
            if (updated.length === 0) {
              offlineEnvelopes.delete(authenticatedUserId);
            } else {
              offlineEnvelopes.set(authenticatedUserId, updated);
            }
            console.log(`[WS] Purged message ${messageId} from ephemeral store upon delivery ACK`);
          }
          break;
        }
      }
    } catch (err) {
      console.error('[WS] Error processing frame:', err);
    }
  });

  ws.on('close', () => {
    if (authenticatedUserId) {
      clients.delete(authenticatedUserId);
      console.log(`[WS] User disconnected: ${authenticatedUserId}`);
    }
  });
});

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`=================================================`);
  console.log(`Zero-Knowledge E2EE Server running on port ${PORT}`);
  console.log(`WebSocket Server listening on ws://localhost:${PORT}`);
  console.log(`=================================================`);
});
