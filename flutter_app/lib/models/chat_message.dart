import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String type;
  final DateTime time;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.type,
    required this.time,
  });

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['time'] as Timestamp?;

    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      type: (data['type'] as String?) ?? 'text',
      time: ts?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'type': type,
      'time': Timestamp.fromDate(time),
    };
  }
}
