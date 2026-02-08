# SuperAIB SDK

The official Flutter SDK for SuperAIB Cloud. A powerful Backend-as-a-Service (BaaS) for building modern apps.

## Features
- 🔐 **Authentication**: Email/Password, Google, Facebook & Impersonation.
- 🗄️ **Database**: NoSQL-style Collections & Documents with powerful querying.
- 📡 **Realtime**: Live WebSocket-based channels and event broadcasting.
- 📁 **Storage**: Manage file metadata, cloud URLs, and storage tracking. 🚀 (NEW)

## Installation
```bash
flutter pub add superaib_sdk

## Installation
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
## 0.4.3

- **New Module**: Added Full Storage Module.
- Features: `createFileRecord` to link cloud files with pgAdmin.
- Features: `listFiles` with pagination support.
- Features: `deleteFile` (Soft delete support).
- Integrated Analytics: Tracking storage usage (MB) and file counts.
- Optimized Realtime: Improved HTTP Fallback for better stability.

## 0.4.2

- **New Module**: Added Full Realtime Support.
- WebSocket-based Channel Subscription and Event Broadcasting.
- Integrated Full Database Module (11 CRUD ops + 7 Query filters).

## 0.4.0

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