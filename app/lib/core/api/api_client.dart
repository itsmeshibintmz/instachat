/// API Client for communicating with the InstaChat backend.
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';

class ApiClient {
  final String baseUrl;
  late final String _wsUrl;
  WebSocketChannel? _wsChannel;

  // Override at build time:
  //   flutter run --dart-define=BASE_URL=http://192.168.1.2:8000
  static const _envUrl = String.fromEnvironment('BASE_URL');

  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
            // Priority: dart-define BASE_URL → platform default
            // Android emulator → 10.0.2.2 maps to host machine localhost.
            // iOS Simulator   → localhost resolves directly.
            // Physical device → pass --dart-define=BASE_URL=http://<mac-ip>:8000
            (_envUrl.isNotEmpty
                ? _envUrl
                : (Platform.isAndroid
                    ? 'http://10.0.2.2:8000'
                    : 'http://localhost:8000')) {
    _wsUrl = this.baseUrl.replaceFirst('http', 'ws');
  }

  // ─── Auth ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password,
      {String? verificationCode}) async {
    final body = {
      'username': username,
      'password': password,
      if (verificationCode != null) 'verification_code': verificationCode,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/auth/logout'));
  }

  Future<Map<String, dynamic>> getSessionStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/status'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Inbox ────────────────────────────────────────────────────────────

  Future<List<ThreadItem>> getInbox({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inbox/?limit=$limit'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch inbox: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final threads = data['threads'] as List<dynamic>;
    return threads
        .map((t) => ThreadItem.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<List<ThreadItem>> getPendingInbox() async {
    final response = await http.get(Uri.parse('$baseUrl/inbox/pending'));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch pending inbox: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final threads = data['threads'] as List<dynamic>;
    return threads
        .map((t) => ThreadItem.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserInfo>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inbox/search?q=${Uri.encodeComponent(query)}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search users: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final users = data['users'] as List<dynamic>;
    return users
        .map((u) => UserInfo.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createThread(
      List<int> userIds, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inbox/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_ids': userIds,
        'message': message,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Messages ─────────────────────────────────────────────────────────

  Future<MessagesPage> getMessages(String threadId,
      {int limit = 50, String? cursor}) async {
    final uri = Uri.parse('$baseUrl/messages/$threadId').replace(
      queryParameters: {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
      },
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch messages: ${response.body}');
    }

    return MessagesPage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> sendText(String threadId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send/text'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'thread_id': threadId,
        'text': text,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reactToMessage(
      String threadId, String messageId, String emoji) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/react'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'thread_id': threadId,
        'message_id': messageId,
        'emoji': emoji,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unreactToMessage(
      String threadId, String messageId, String emoji) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/unreact'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'thread_id': threadId,
        'message_id': messageId,
        'emoji': emoji,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> markSeen(String threadId, String messageId) async {
    await http.post(
      Uri.parse('$baseUrl/messages/$threadId/seen?message_id=$messageId'),
    );
  }

  // ─── Media ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendPhoto(
      String threadId, File photo) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/media/send/photo'),
    );
    request.fields['thread_id'] = threadId;
    request.files.add(await http.MultipartFile.fromPath('file', photo.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendVideo(
      String threadId, File video) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/media/send/video'),
    );
    request.fields['thread_id'] = threadId;
    request.files.add(await http.MultipartFile.fromPath('file', video.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendVoice(
      String threadId, File audio) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/media/send/voice'),
    );
    request.fields['thread_id'] = threadId;
    request.files.add(await http.MultipartFile.fromPath('file', audio.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── WebSocket ────────────────────────────────────────────────────────

  WebSocketChannel connectWebSocket() {
    _wsChannel = WebSocketChannel.connect(Uri.parse('$_wsUrl/ws'));
    return _wsChannel!;
  }

  void disconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
  }
}
