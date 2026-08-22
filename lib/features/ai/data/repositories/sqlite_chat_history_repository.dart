import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../../shared/models/chat_message.dart';
import '../../domain/repositories/chat_history_repository.dart';

class SqliteChatHistoryRepository implements ChatHistoryRepository {
  SqliteChatHistoryRepository({Database? database}) : _provided = database;

  final Database? _provided;
  Database? _db;

  Future<Database> get _database async {
    if (_provided != null) return _provided;
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, 'jobsensei_chat.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            text TEXT NOT NULL,
            author TEXT NOT NULL,
            sent_at INTEGER NOT NULL,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE attachments (
            id TEXT PRIMARY KEY,
            message_id TEXT NOT NULL,
            name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            kind TEXT NOT NULL,
            size_bytes INTEGER NOT NULL,
            url TEXT,
            local_path TEXT,
            FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  @override
  Future<List<ChatConversation>> loadConversations() async {
    final db = await _database;
    final rows = await db.query('conversations', orderBy: 'updated_at DESC');
    final conversations = <ChatConversation>[];
    for (final row in rows) {
      conversations.add(await _conversationFrom(db, row));
    }
    return conversations;
  }

  @override
  Future<void> saveConversation(ChatConversation conversation) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(
        'conversations',
        {
          'id': conversation.id,
          'title': conversation.title,
          'created_at': conversation.createdAt.millisecondsSinceEpoch,
          'updated_at': conversation.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'attachments',
        where:
            'message_id IN (SELECT id FROM messages WHERE conversation_id = ?)',
        whereArgs: [conversation.id],
      );
      await txn.delete(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversation.id],
      );
      for (final message in conversation.messages) {
        await txn.insert('messages', {
          'id': message.id,
          'conversation_id': conversation.id,
          'text': message.text,
          'author': message.author.name,
          'sent_at': message.sentAt.millisecondsSinceEpoch,
        });
        for (final attachment in message.attachments) {
          await txn.insert('attachments', {
            'id': attachment.id,
            'message_id': message.id,
            'name': attachment.name,
            'mime_type': attachment.mimeType,
            'kind': attachment.kind.name,
            'size_bytes': attachment.sizeBytes,
            'url': attachment.url,
            'local_path': attachment.localPath,
          });
        }
      }
    });
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final db = await _database;
    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<ChatConversation> _conversationFrom(
    Database db,
    Map<String, Object?> row,
  ) async {
    final conversationId = row['id'] as String;
    final messageRows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'sent_at ASC',
    );
    final messages = <ChatMessage>[];
    for (final messageRow in messageRows) {
      final messageId = messageRow['id'] as String;
      final attachmentRows = await db.query(
        'attachments',
        where: 'message_id = ?',
        whereArgs: [messageId],
      );
      messages.add(
        ChatMessage(
          id: messageId,
          text: messageRow['text'] as String,
          author: (messageRow['author'] as String) == 'user'
              ? MessageAuthor.user
              : MessageAuthor.sensei,
          sentAt: DateTime.fromMillisecondsSinceEpoch(
            messageRow['sent_at'] as int,
          ),
          attachments: attachmentRows
              .map(
                (item) => ChatAttachment(
                  id: item['id'] as String,
                  name: item['name'] as String,
                  mimeType: item['mime_type'] as String,
                  kind: (item['kind'] as String) == 'image'
                      ? ChatAttachmentKind.image
                      : ChatAttachmentKind.document,
                  sizeBytes: item['size_bytes'] as int,
                  url: item['url'] as String?,
                  localPath: item['local_path'] as String?,
                ),
              )
              .toList(),
        ),
      );
    }

    return ChatConversation(
      id: conversationId,
      title: row['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      messages: messages,
    );
  }
}
