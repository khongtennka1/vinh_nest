import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id; // conversationId (doc.id)
  final String peerId; // id của người kia
  final String name; // peerName
  final String lastMessage;
  final DateTime time; // lastMessageTime
  final int unread; // số tin chưa đọc của currentUser
  final String avatarUrl; // peerAvatarUrl

  Conversation({
    required this.id,
    required this.peerId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.avatarUrl,
  });

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['lastMessageTime'] as Timestamp?;

    return Conversation(
      id: doc.id,
      peerId: (data['peerId'] as String?) ?? '',
      name: (data['peerName'] as String?) ?? 'Người dùng',
      lastMessage: (data['lastMessage'] as String?) ?? '',
      time: ts?.toDate() ?? DateTime.now(),
      unread: (data['unread'] as int?) ?? 0,
      avatarUrl:
          (data['peerAvatarUrl'] as String?) ??
          'https://i.pravatar.cc/150?u=${doc.id}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'peerName': name,
      'peerAvatarUrl': avatarUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(time),
      'unread': unread,
    };
  }
}
