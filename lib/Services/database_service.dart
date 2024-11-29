import 'package:ollama_chat/Models/ollama_chat.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class DatabaseService {
  late Database _db;

  Future<void> open(String databaseFile) async {
    _db = await openDatabase(
      path.join(await getDatabasesPath(), databaseFile),
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''CREATE TABLE IF NOT EXISTS chats (
chat_id TEXT PRIMARY KEY,
model TEXT NOT NULL,
chat_title TEXT NOT NULL,
system_prompt TEXT,
options TEXT
) WITHOUT ROWID;''');

        await db.execute('''CREATE TABLE IF NOT EXISTS messages (
message_id TEXT PRIMARY KEY,
chat_id TEXT NOT NULL,
content TEXT NOT NULL,
role TEXT CHECK(role IN ('user', 'assistant', 'system')) NOT NULL,
timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (chat_id) REFERENCES chats(chat_id) ON DELETE CASCADE
) WITHOUT ROWID;''');
      },
    );
  }

  Future<void> close() async => _db.close();

  // Chat Operations

  Future<OllamaChat> createChat(String model) async {
    final id = Uuid().v4();

    await _db.insert('chats', {
      'chat_id': id,
      'model': model,
      'chat_title': 'New Chat',
      'system_prompt': null,
      'options': null,
    });

    return (await getChat(id))!;
  }

  Future<OllamaChat?> getChat(String chatId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'chats',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );

    if (maps.isEmpty) {
      return null;
    } else {
      return OllamaChat.fromMap(maps.first);
    }
  }

  Future<void> updateChat(
    OllamaChat chat, {
    String? newModel,
    String? newTitle,
    String? newSystemPrompt,
    String? newOptions,
  }) async {
    await _db.update(
      'chats',
      {
        'model': newModel ?? chat.model,
        'chat_title': newTitle ?? chat.title,
        'system_prompt': newSystemPrompt ?? chat.systemPrompt,
        'options': newOptions ?? chat.options,
      },
      where: 'chat_id = ?',
      whereArgs: [chat.id],
    );
  }

  Future<void> deleteChat(String chatId) async {
    await _db.delete(
      'chats',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );

    await _db.delete(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  Future<List<OllamaChat>> getAllChats() async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
        '''SELECT chats.chat_id, chats.model, chats.chat_title, chats.system_prompt, chats.options, MAX(messages.timestamp) AS last_update
FROM chats
LEFT JOIN messages ON chats.chat_id = messages.chat_id
GROUP BY chats.chat_id
ORDER BY last_update DESC;''');

    return List.generate(maps.length, (i) {
      return OllamaChat.fromMap(maps[i]);
    });
  }

  // Message Operations

  Future<void> addMessage(
    OllamaMessage message, {
    required OllamaChat chat,
  }) async {
    // TODO: Get parameters from instance method like toDatabaseParams

    await _db.insert('messages', {
      'message_id': message.id,
      'chat_id': chat.id,
      'content': message.content,
      'role': message.role.toString().split('.').last,
      'timestamp': message.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<OllamaMessage?> getMessage(String messageId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'messages',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );

    if (maps.isEmpty) {
      return null;
    } else {
      return OllamaMessage.fromDatabase(maps.first);
    }
  }

  Future<void> updateMessage(
    OllamaMessage message, {
    String? newContent,
  }) async {
    await _db.update(
      'messages',
      {
        'content': newContent ?? message.content,
      },
      where: 'message_id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await _db.delete(
      'messages',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<OllamaMessage>> getMessages(String chatId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return OllamaMessage.fromDatabase(maps[i]);
    });
  }

  Future<void> deleteMessages(List<OllamaMessage> messages) async {
    await _db.transaction((txn) async {
      for (final message in messages) {
        await txn.delete(
          'messages',
          where: 'message_id = ?',
          whereArgs: [message.id],
        );
      }
    });
  }
}
