import 'dart:convert';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import '../settings/translation_ai_settings.dart';

class AiServiceClient {
  AiServiceClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> generateText({
    required AiServiceConfig service,
    required String apiKey,
    required String prompt,
    int maxOutputTokens = 800,
  }) async {
    final base = service.baseUrl.trim();
    if (base.isEmpty) {
      throw ArgumentError('AI service baseUrl is empty');
    }
    final model = service.defaultModel.trim();
    if (model.isEmpty) {
      throw ArgumentError('AI service model is empty');
    }
    final key = apiKey.trim();
    if (key.isEmpty) throw ArgumentError('AI service apiKey is empty');

    try {
      return switch (service.apiType) {
        AiServiceApiType.openAiChatCompletions => await _openAiChatCompletions(
          baseUrl: base,
          model: model,
          apiKey: key,
          prompt: prompt,
          maxOutputTokens: maxOutputTokens,
        ),
        AiServiceApiType.openAiResponses => await _openAiResponses(
          baseUrl: base,
          model: model,
          apiKey: key,
          prompt: prompt,
          maxOutputTokens: maxOutputTokens,
        ),
        AiServiceApiType.gemini => await _geminiGenerateContent(
          baseUrl: base,
          model: model,
          apiKey: key,
          prompt: prompt,
          maxOutputTokens: maxOutputTokens,
        ),
        AiServiceApiType.anthropic => await _anthropicMessages(
          baseUrl: base,
          model: model,
          apiKey: key,
          prompt: prompt,
          maxOutputTokens: maxOutputTokens,
        ),
      };
    } catch (e, s) {
      AppLogger.e(
        'AI request failed',
        tag: 'ai',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Uri _baseUri(String baseUrl) {
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalized);
  }

  Future<String> _openAiChatCompletions({
    required String baseUrl,
    required String model,
    required String apiKey,
    required String prompt,
    required int maxOutputTokens,
  }) async {
    final uri = _baseUri(baseUrl).resolve('chat/completions');
    final res = await _dio.postUri<Map<String, Object?>>(
      uri,
      data: <String, Object?>{
        'model': model,
        'messages': [
          <String, Object?>{'role': 'user', 'content': prompt},
        ],
        'max_tokens': maxOutputTokens,
      },
      options: Options(
        headers: <String, Object?>{
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );
    final data = res.data;
    if (data == null) throw StateError('Empty response');

    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is String) return content.trim();
        }
      }
    }
    throw StateError('Unexpected OpenAI chat completion response');
  }

  Future<String> _openAiResponses({
    required String baseUrl,
    required String model,
    required String apiKey,
    required String prompt,
    required int maxOutputTokens,
  }) async {
    final uri = _baseUri(baseUrl).resolve('responses');
    final res = await _dio.postUri<Map<String, Object?>>(
      uri,
      data: <String, Object?>{
        'model': model,
        'input': prompt,
        'max_output_tokens': maxOutputTokens,
      },
      options: Options(
        headers: <String, Object?>{
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );
    final data = res.data;
    if (data == null) throw StateError('Empty response');

    final outputText = data['output_text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }

    final output = data['output'];
    if (output is List) {
      final buf = StringBuffer();
      for (final item in output) {
        if (item is! Map) continue;
        final content = item['content'];
        if (content is! List) continue;
        for (final c in content) {
          if (c is! Map) continue;
          final type = c['type'];
          final text = c['text'];
          if (type == 'output_text' && text is String) {
            if (buf.isNotEmpty) buf.write('\n');
            buf.write(text);
          }
        }
      }
      final out = buf.toString().trim();
      if (out.isNotEmpty) return out;
    }

    // Some OpenAI-compatible APIs still return choices.
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final text = first['text'];
        if (text is String && text.trim().isNotEmpty) return text.trim();
        final message = first['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    }

    throw StateError('Unexpected OpenAI responses response');
  }

  Future<String> _geminiGenerateContent({
    required String baseUrl,
    required String model,
    required String apiKey,
    required String prompt,
    required int maxOutputTokens,
  }) async {
    final base = _baseUri(baseUrl);
    final uri = base
        .resolve('models/$model:generateContent')
        .replace(queryParameters: <String, String>{'key': apiKey});
    final res = await _dio.postUri<Map<String, Object?>>(
      uri,
      data: <String, Object?>{
        'contents': [
          <String, Object?>{
            'role': 'user',
            'parts': [
              <String, Object?>{'text': prompt},
            ],
          },
        ],
        'generationConfig': <String, Object?>{'maxOutputTokens': maxOutputTokens},
      },
      options: Options(
        headers: const <String, Object?>{'Content-Type': 'application/json'},
        responseType: ResponseType.json,
      ),
    );
    final data = res.data;
    if (data == null) throw StateError('Empty response');

    final candidates = data['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map) {
        final content = first['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final p0 = parts.first;
            if (p0 is Map) {
              final text = p0['text'];
              if (text is String) return text.trim();
            }
          }
        }
      }
    }
    throw StateError('Unexpected Gemini response');
  }

  Future<String> _anthropicMessages({
    required String baseUrl,
    required String model,
    required String apiKey,
    required String prompt,
    required int maxOutputTokens,
  }) async {
    final uri = _baseUri(baseUrl).resolve('v1/messages');
    final res = await _dio.postUri<Map<String, Object?>>(
      uri,
      data: <String, Object?>{
        'model': model,
        'max_tokens': maxOutputTokens,
        'messages': [
          <String, Object?>{'role': 'user', 'content': prompt},
        ],
      },
      options: Options(
        headers: <String, Object?>{
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );
    final data = res.data;
    if (data == null) throw StateError('Empty response');

    final content = data['content'];
    if (content is List) {
      final buf = StringBuffer();
      for (final item in content) {
        if (item is! Map) continue;
        final type = item['type'];
        final text = item['text'];
        if (type == 'text' && text is String) {
          if (buf.isNotEmpty) buf.write('\n');
          buf.write(text);
        }
      }
      final out = buf.toString().trim();
      if (out.isNotEmpty) return out;
    }

    final completion = data['completion'];
    if (completion is String && completion.trim().isNotEmpty) {
      return completion.trim();
    }

    throw StateError('Unexpected Anthropic response');
  }
}

String prettyJson(Object? v) {
  try {
    return const JsonEncoder.withIndent('  ').convert(v);
  } catch (_) {
    return v.toString();
  }
}

