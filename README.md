# SuperAIB SDK

The official Flutter SDK for SuperAIB Cloud.

## Features
- 🔐 **Authentication**: Email/Password, Google, Facebook & Impersonation.
- 🗄️ **Database**: NoSQL-style Collections & Documents (11 CRUD + 7 Query ops).
- 📡 **Realtime**: Live WebSocket events & channels.

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

### Tallaabada 3: Cusboonaysii `CHANGELOG.md`
Tani waa khasab si dadku u ogaadaan waxa ku cusub version-ka **0.1.0**.

```markdown
## 0.4.0

- **New Feature**: Added Full Database Module.
- Supported 11 CRUD operations: `add`, `get`, `set`, `update`, `upsert`, `delete`, `exists`, `increment`, `count`.
- Supported 7 Query & Filtering operations: `where`, `orWhere`, `select`, `search`, `orderBy`, `limit`, `offset`.
- Integrated Analytics and Usage tracking for database operations.

##  0.4.0

- Initial release with Authentication module.


- **New Module**: Added Full Realtime Support via WebSockets.
- Features: Auto-reconnection with Exponential Backoff.
- Features: Dynamic Identity Management (`setIdentity` / `clearIdentity`).
- Features: Channel Subscription and Event Broadcasting.
- Features: Presence Tracking (Join/Leave events).


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