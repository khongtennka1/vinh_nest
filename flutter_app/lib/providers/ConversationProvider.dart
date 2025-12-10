// Gợi ý hàm trong ConversationProvider.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'conversations';

  Future<String> getOrCreateConversation({
    required String myId,
    required String peerId,
    required String peerName,
    String? peerAvatar,
  }) async {
    List<String> parts = [myId, peerId];
    parts.sort();
    final stableId = parts.join('_');

    final docRef = _firestore.collection(collection).doc(stableId);

    final snapshot = await docRef.get();
    if (snapshot.exists) {
      return stableId;
    }

    final now = Timestamp.now();
    await docRef.set({
      'id': stableId,
      'participantIds': [myId, peerId],
      'participants': {
        myId: {'id': myId},
        peerId: {'id': peerId, 'name': peerName, 'avatar': peerAvatar},
      },
      'lastMessage': '',
      'lastMessageTime': now,
      'createdAt': now,
      'unreadCount': {myId: 0, peerId: 0},
    }, SetOptions(merge: true));

    return stableId;
  }
}
