import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dtj9taiqd";
  static const String uploadPreset = "room_rental";

  static Future<String?> uploadFile(String localPath) async {
    try {
      final url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      final request = http.MultipartRequest("POST", Uri.parse(url))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', localPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (streamedResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['secure_url'] as String?;
      } else {
        print("Cloudinary upload failed: ${response.statusCode} -> ${response.body}");
        return null;
      }
    } catch (e) {
      print("Cloudinary upload exception: $e");
      return null;
    }
  }
}
