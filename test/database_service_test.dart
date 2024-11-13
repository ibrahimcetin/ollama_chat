import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test("Test database open", () async {
    final service = DatabaseService();

    await service.open('test_database.db');
  });

  test("Test database create chat", () async {
    final service = DatabaseService();

    await service.open('test_database.db');

    final chat = await service.createChat("llama3.2-vision");

    expect(chat.id, isPositive);
    expect(chat.model, equals("llama3.2-vision"));
    expect(chat.title, "New Chat");
    expect(chat.options, isNull);
  });

  test("Test database add message", () async {
    final service = DatabaseService();

    await service.open('test_database.db');

    final message = OllamaMessage(
      "Hello, this is a test message.",
      role: OllamaMessageRole.user,
    );

    await service.addMessage(message, 1);
  });

  test("Test database get all chats", () async {
    final service = DatabaseService();

    await service.open('test_database.db');

    final chats = await service.getAllChats();

    if (chats.isNotEmpty) {
      expect(chats.first.id, isPositive);
      expect(chats.first.model, equals("llama3.2-vision"));
      expect(chats.first.title, "New Chat");
      expect(chats.first.options, isNull);
    }
  });
}
