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
## 0.1.0

- **New Feature**: Added Full Database Module.
- Supported 11 CRUD operations: `add`, `get`, `set`, `update`, `upsert`, `delete`, `exists`, `increment`, `count`.
- Supported 7 Query & Filtering operations: `where`, `orWhere`, `select`, `search`, `orderBy`, `limit`, `offset`.
- Integrated Analytics and Usage tracking for database operations.

## 0.0.1

- Initial release with Authentication module.

