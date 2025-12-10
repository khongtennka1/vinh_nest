import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyACju8Cf3hXvHBdl8Wp_GJdaBFLsNqT1Hw';

  static const String _model = 'gemini-2.5-flash';

  static Future<String> detectVersion() async {
    final versions = ['v1', 'v1beta'];

    for (final v in versions) {
      final url =
          'https://generativelanguage.googleapis.com/$v/models?key=$_apiKey';

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['models'] is List) {
          final models = data['models'] as List;

          final found = models.any((m) => m['name'] == "models/$_model");

          if (found) return v;
        }
      }
    }

    return 'not_found';
  }

  static Future<String> generateResponse(String prompt) async {
    final version = await detectVersion();

    final url = "https://generativelanguage.googleapis.com/$version/models/$_model:generateContent?key=$_apiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text is String) {
          return text;
        } else {
          return "Không nhận được phản hồi hợp lệ từ AI.";
        }
      } else {
        return "Lỗi ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}
