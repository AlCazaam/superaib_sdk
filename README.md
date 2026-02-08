# SuperAIB SDK 🚀

The official Flutter SDK for SuperAIB Cloud. Build scalable apps with ease using our 5 core pillars.

## 🌟 Features
- 🔐 **Authentication**: Email/Password, Social Login, and Impersonation.
- 🗄️ **Database**: Powerful NoSQL Documents & Collections with advanced querying.
- 📡 **Realtime**: Live event broadcasting and channel subscriptions (HTTP Polling Optimized).
- 📁 **Storage**: Binary file uploads to Cloudinary with metadata tracking in pgAdmin.
- 🔔 **Notifications**: Live in-app notifications and broadcast alerts.

## 🚀 Installation
```bash
flutter pub add superaib_sdk

Usage Example (Database)

// Add a document
await SuperAIB.instance.db.collection('tasks').add({'title': 'Build BaaS'});

// Advanced Query
final docs = await SuperAIB.instance.db
    .collection('products')
    .where('price', '<', 500)
    .orderBy('price')
    .limit(10)
    .get();


---
### 3. `CHANGELOG.md` (Update History)

```markdown
## 0.4.5

- **New Module**: Added Full Storage Module.
- Features: `createFileRecord` to link cloud files with pgAdmin.
- Features: `listFiles` with pagination support.
- Features: `deleteFile` (Soft delete support).
- Integrated Analytics: Tracking storage usage (MB) and file counts.
- Optimized Realtime: Improved HTTP Fallback for better stability.

## 0.4.5

- **New Module**: Added Full Realtime Support.
- WebSocket-based Channel Subscription and Event Broadcasting.
- Integrated Full Database Module (11 CRUD ops + 7 Query filters).

## 0.4.5

- Initial release with Authentication module (Email/Password, Social, Impersonation).

## Usage Example (Realtime)
```dart
// 1. Connect
SuperAIB.instance.realtime.connect();

// 2. Set user identity (Optional)
SuperAIB.instance.setIdentity("user_123");

// 3. Subscribe to a channel
final myChannel = SuperAIB.instance.realtime.channel('chat_room');
myChannel.subscribe();

// 4. Listen for messages
myChannel.on('new_message', (payload) {
  print("Fariin: $payload");
});

// 5. Broadcast live
myChannel.broadcast(event: 'typing', payload: {'status': true});

Usage Example (Storage)

// 1. Save a file record in pgAdmin
await SuperAIB.instance.storage.createFileRecord(
  fileName: "vacation.mp4",
  fileType: "video/mp4",
  sizeMB: 45.2,
  url: "https://your-cloud-storage.com/files/vacation.mp4",
  metadata: {"location": "Zanzibar"},
);

// 2. List all project files
final files = await SuperAIB.instance.storage.listFiles(page: 1, pageSize: 10);

// 3. Delete a file record
await SuperAIB.instance.storage.deleteFile("file_uuid_here");


Usage Example (Realtime)

// Subscribe to live events
final chatChannel = await SuperAIB.instance.realtime.channel('global_chat');
chatChannel?.subscribe();

chatChannel?.on('NEW_MESSAGE', (payload) {
  print("New Chat: ${payload['text']}");
});

4. Live Notifications

SuperAIB.instance.notifications.onNotificationReceived((data) {
  print("🔔 New Alert: ${data['title']} - ${data['body']}");
});

---

### 3. `CHANGELOG.md` (The Evolution)

```markdown
## 0.4.5

- **New Module**: Added Full Notifications Module (`onNotificationReceived` / `sendBroadcast`).
- **Storage Update**: Supported Binary File Uploads (`uploadFile`) directly to Cloudinary via Backend.
- **Realtime Stability**: Optimized `channel()` to be `Future`-based for better pgAdmin sync.
- **Improved Security**: Integrated Auth Identity across all modules.

## 0.4.5

- Minor fixes for WebSocket Handshake in iOS Simulators.
- Added automatic project ID detection in Middleware.

## 0.4.5

- Initial release with Authentication and Database modules.
- Integrated Realtime WebSocket support.
