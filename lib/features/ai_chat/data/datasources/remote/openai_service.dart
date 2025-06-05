// features/ai_chat/data/datasources/remote/openai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mytuition/core/result/result.dart';

class OpenAIService {
  final http.Client httpClient;
  final FirebaseRemoteConfig remoteConfig;

  static const String baseUrl = 'https://api.openai.com/v1';

  static const String assistantPrompt = '''
You are a helpful AI tutor for primary school students (ages 6-12) in Malaysia. Your role is to:

1. **Educational Support**: Help with subjects like Math, Science, English, Bahasa Malaysia, and Chinese
2. **Simple Language**: Use age-appropriate, simple language that primary students can understand
3. **Encouraging Tone**: Always be positive, patient, and encouraging
4. **Safe Learning**: Only provide educational content suitable for children
5. **Step-by-Step**: Break down complex concepts into simple, easy-to-follow steps
6. **Examples**: Use relatable examples from everyday life
7. **Interactive**: Ask follow-up questions to ensure understanding

**Guidelines:**
- Keep responses under 150 words when possible
- Use simple emojis occasionally to make learning fun 😊📚✨
- If asked about non-educational topics, gently redirect to learning
- Encourage students to think through problems step-by-step
- Praise effort and progress, not just correct answers
- Use encouraging phrases like "Great question!", "You're doing well!", "Let's figure this out together!"

**Response Format:**
- Start with a friendly greeting or acknowledgment
- Explain concepts in simple, clear steps
- Use examples that kids can relate to
- End with encouragement or a follow-up question

Remember: You're helping young learners, so be patient, kind, and make learning enjoyable!
''';

  OpenAIService({
    required this.httpClient,
    required this.remoteConfig,
  });

  Future<Result<String>> _getApiKey() async {
    return ResultFactory.tryAsync(() async {
      print('Fetching OpenAI API key from Remote Config...');
      await remoteConfig.fetchAndActivate();
      final apiKey = remoteConfig.getString('openai_api_key');

      if (apiKey.isEmpty) {
        throw Exception('OpenAI API key not found in Remote Config');
      }

      print('API key found: ${apiKey.length} characters');
      return apiKey;
    });
  }

  Future<Result<String>> _getAssistantId() async {
    final configResult = await ResultFactory.tryAsync(() async {
      await remoteConfig.fetchAndActivate();
      return remoteConfig.getString('openai_assistant_id');
    });

    return switch (configResult) {
      Error(message: final message) => Error(message),
      Success(data: final assistantId) =>
        assistantId.isEmpty ? await _createAssistant() : Success(assistantId),
    };
  }

  Future<Result<String>> _createAssistant() async {
    print('Creating new OpenAI Assistant...');

    final apiKeyResult = await _getApiKey();

    return switch (apiKeyResult) {
      Error(message: final message) => Error(message),
      Success(data: final apiKey) => await _createAssistantWithKey(apiKey),
    };
  }

  Future<Result<String>> _createAssistantWithKey(String apiKey) async {
    return ResultFactory.tryAsync(() async {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/assistants'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=utf-8',
          // FIXED: Add charset
          'OpenAI-Beta': 'assistants=v2',
        },
        body: utf8.encode(jsonEncode({
          // FIXED: Explicit UTF-8 encoding
          'name': 'Primary School Tutor',
          'instructions': assistantPrompt,
          'model': 'gpt-4o-mini',
          'tools': [],
          'temperature': 0.7,
          'top_p': 0.9,
        })),
      );

      if (response.statusCode == 200) {
        // FIXED: Explicit UTF-8 decoding
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        final assistantId = data['id'] as String;
        print('Assistant created successfully: $assistantId');
        return assistantId;
      } else {
        print(
            'Failed to create assistant: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create assistant: ${response.body}');
      }
    });
  }

  Future<Result<String>> createThread() async {
    print('Creating new OpenAI thread...');

    final apiKeyResult = await _getApiKey();

    return switch (apiKeyResult) {
      Error(message: final message) => Error(message),
      Success(data: final apiKey) => await _createThreadWithKey(apiKey),
    };
  }

  Future<Result<String>> _createThreadWithKey(String apiKey) async {
    return ResultFactory.tryAsync(() async {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/threads'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=utf-8',
          // FIXED: Add charset
          'OpenAI-Beta': 'assistants=v2',
        },
      );

      if (response.statusCode == 200) {
        // FIXED: Explicit UTF-8 decoding
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        final threadId = data['id'] as String;
        print('Thread created successfully: $threadId');
        return threadId;
      } else {
        print(
            'Failed to create thread: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create thread: ${response.body}');
      }
    });
  }

  Future<Result<String>> sendMessageToThread({
    required String threadId,
    required String message,
  }) async {
    print('Sending message to thread: $threadId');
    print(
        'Message: ${message.length > 50 ? message.substring(0, 50) + '...' : message}');

    final apiKeyResult = await _getApiKey();
    final assistantIdResult = await _getAssistantId();

    return switch ((apiKeyResult, assistantIdResult)) {
      (Error(message: final message), _) => Error(message),
      (_, Error(message: final message)) => Error(message),
      (Success(data: final apiKey), Success(data: final assistantId)) =>
        await _sendMessageWithCredentials(
            threadId, message, apiKey, assistantId),
    };
  }

  Future<Result<String>> _sendMessageWithCredentials(
    String threadId,
    String message,
    String apiKey,
    String assistantId,
  ) async {
    return ResultFactory.tryAsync(() async {
      // Step 1: Add message to thread
      print('Adding user message to thread...');
      final messageResponse = await httpClient.post(
        Uri.parse('$baseUrl/threads/$threadId/messages'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=utf-8',
          // FIXED: Add charset
          'OpenAI-Beta': 'assistants=v2',
        },
        body: utf8.encode(jsonEncode({
          // FIXED: Explicit UTF-8 encoding
          'role': 'user',
          'content': message,
        })),
      );

      if (messageResponse.statusCode != 200) {
        throw Exception('Failed to add message: ${messageResponse.body}');
      }

      // Step 2: Create run
      print('Creating run with assistant: $assistantId');
      final runResponse = await httpClient.post(
        Uri.parse('$baseUrl/threads/$threadId/runs'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=utf-8',
          // FIXED: Add charset
          'OpenAI-Beta': 'assistants=v2',
        },
        body: utf8.encode(jsonEncode({
          // FIXED: Explicit UTF-8 encoding
          'assistant_id': assistantId,
          'max_prompt_tokens': 3000,
          'max_completion_tokens': 500,
        })),
      );

      if (runResponse.statusCode != 200) {
        throw Exception('Failed to create run: ${runResponse.body}');
      }

      // FIXED: Explicit UTF-8 decoding
      final runResponseBody = utf8.decode(runResponse.bodyBytes);
      final runData = jsonDecode(runResponseBody);
      final runId = runData['id'];
      print('Run created: $runId');

      // Step 3: Wait for completion
      print('Waiting for run completion...');
      await _waitForRunCompletion(threadId, runId, apiKey);

      // Step 4: Get the response
      print('Fetching AI response...');
      return await _getLatestResponse(threadId, apiKey);
    });
  }

  Future<void> _waitForRunCompletion(
      String threadId, String runId, String apiKey) async {
    int attempts = 0;
    const maxAttempts = 60;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      attempts++;

      final response = await httpClient.get(
        Uri.parse('$baseUrl/threads/$threadId/runs/$runId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'OpenAI-Beta': 'assistants=v2',
        },
      );

      if (response.statusCode == 200) {
        // FIXED: Explicit UTF-8 decoding
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        final status = data['status'];

        print('Run status: $status (attempt $attempts)');

        if (status == 'completed') {
          print('Run completed successfully');
          break;
        } else if (status == 'failed' ||
            status == 'cancelled' ||
            status == 'expired') {
          throw Exception('Run failed with status: $status');
        } else if (status == 'requires_action') {
          throw Exception(
              'Run requires action - not supported in this implementation');
        }
      } else {
        throw Exception('Failed to check run status: ${response.body}');
      }
    }

    if (attempts >= maxAttempts) {
      throw Exception('Run timed out after $maxAttempts seconds');
    }
  }

  Future<String> _getLatestResponse(String threadId, String apiKey) async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl/threads/$threadId/messages?limit=1'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
    );

    if (response.statusCode == 200) {
      // FIXED: Explicit UTF-8 decoding for emoji support
      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);
      final messages = data['data'] as List;

      if (messages.isNotEmpty) {
        final latestMessage = messages.first;
        final content = latestMessage['content'] as List;

        if (content.isNotEmpty && content.first['type'] == 'text') {
          final responseText = content.first['text']['value'] as String;
          print('AI response received: ${responseText.length} characters');

          // FIXED: Ensure proper string handling for emojis
          final cleanedResponse = _cleanEmojiString(responseText);
          print(
              'Cleaned response preview: ${cleanedResponse.length > 50 ? cleanedResponse.substring(0, 50) + '...' : cleanedResponse}');

          return cleanedResponse;
        }
      }
    }

    print('Failed to get response: ${response.statusCode} - ${response.body}');
    throw Exception('Failed to get response: ${response.body}');
  }

  // ADDED: Helper method to clean emoji strings
  String _cleanEmojiString(String input) {
    // Handle any potential encoding issues with emojis
    try {
      // Convert to UTF-8 bytes and back to ensure proper encoding
      final bytes = utf8.encode(input);
      final cleaned = utf8.decode(bytes, allowMalformed: false);
      return cleaned;
    } catch (e) {
      print('Emoji cleaning error: $e');
      // Fallback: return original string
      return input;
    }
  }
}
