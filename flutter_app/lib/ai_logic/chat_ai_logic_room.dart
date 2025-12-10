import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatAiLogic {
  static bool isAskTotalRooms(String text) {
    final t = text.toLowerCase();
    return t.contains("tong so phong") ||
        t.contains("bao nhieu phong") ||
        t.contains("co bao nhieu phong tat ca") ||
        t.contains("toa nha cua toi dang co bao nhieu phong");
  }

  static bool isAskAvailableRooms(String text) {
    final t = text.toLowerCase();
    return t.contains("phong con trong") ||
        t.contains("chua thue") ||
        t.contains("con bao nhieu phong trong");
  }

  static bool isAskRentedRoom(String text) {
    final t = text.toLowerCase();
    return t.contains("phong da thue") ||
        t.contains("da thue") ||
        t.contains("so phong da thue");
  }

  static bool isAskMaintainRoom(String text) {
    final t = text.toLowerCase();
    return t.contains("phong trong qua trinh sua chua") ||
        t.contains("dang bao tri") ||
        t.contains("bao tri phong") || 
        t.contains("dang trong qua trinh bao tri");
  }

  static Future<List<Map<String, dynamic>>> getCheapestRooms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> allRooms = [];

    final hostels = await firestore
        .collection("hostels")
        .where("ownerId", isEqualTo: user.uid)
        .get();

    for (var h in hostels.docs) {
      final roomsSnap = await firestore
          .collection("hostels")
          .doc(h.id)
          .collection("rooms")
          .where("price", isGreaterThan: 0)
          .orderBy("price") //thap -> cao (ascending)
          .limit(5)
          .get();

      for (var r in roomsSnap.docs) {
        allRooms.add({
          "id": r.id,
          "hostelId": h.id,
          "title": r["title"] ?? "Không tên",
          "price": r["price"] ?? 0,
          "status": r["status"] ?? "unknown",
          "description": r["description"] ?? "",
        });
      }
    }

    //sort theo thu tu tang dan (compareTo -> nho dung truoc)
    allRooms.sort((a, b) => (a["price"] as num).compareTo(b["price"] as num));

    if (allRooms.length > 5) {
      allRooms = allRooms.sublist(0, 5);
    }

    return allRooms;
  }

  static Future<List<Map<String, dynamic>>> getExpensiveRooms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> allRooms = [];

    final hostels = await firestore
        .collection("hostels")
        .where("ownerId", isEqualTo: user.uid)
        .get();

    for (var h in hostels.docs) {
      final roomsSnap = await firestore
          .collection("hostels")
          .doc(h.id)
          .collection("rooms")
          .where("price", isGreaterThan: 0)
          .orderBy("price", descending: true) //cao -> thap
          .limit(5)
          .get();

      for (var r in roomsSnap.docs) {
        allRooms.add({
          "id": r.id,
          "hostelId": h.id,
          "title": r["title"] ?? "Không tên",
          "price": r["price"] ?? 0,
          "status": r["status"] ?? "unknown",
          "description": r["description"] ?? "",
        });
      }
    }

    //sort theo thu tu giam dan (compareTo -> lon dung truoc)
    allRooms.sort((a, b) => (b["price"] as num).compareTo(a["price"] as num));

    if (allRooms.length > 5) {
      allRooms = allRooms.sublist(0, 5);
    }

    return allRooms;
  }

  static Future<int> countTotalRooms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    int total = 0;

    final hostels = await FirebaseFirestore.instance
        .collection("hostels")
        .where("ownerId", isEqualTo: user.uid)
        .get();

    for (var h in hostels.docs) {
      final roomsSnap = await FirebaseFirestore.instance
          .collection("hostels")
          .doc(h.id)
          .collection("rooms")
          .get();

      total += roomsSnap.size;
    }

    return total;
  }

  static Future<int> countAvailableRooms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    int total = 0;

    final hostels = await FirebaseFirestore.instance
        .collection("hostels")
        .where("ownerId", isEqualTo: user.uid)
        .get();

    for (var h in hostels.docs) {
      final roomsSnap = await FirebaseFirestore.instance
          .collection("hostels")
          .doc(h.id)
          .collection("rooms")
          .where("status", isEqualTo: "available")
          .get();

      total += roomsSnap.size;
    }

    return total;
  }

  static Future<int> countRentedRooms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    int total = 0;

    final hostels = await FirebaseFirestore.instance
        .collection("hostels")
        .where("ownerId", isEqualTo: user.uid)
        .get();

    for (var h in hostels.docs) {
      final roomsSnap = await FirebaseFirestore.instance
          .collection("hostels")
          .doc(h.id)
          .collection("rooms")
          .where("status", isEqualTo: "rented")
          .get();

      total += roomsSnap.size;
    }

    return total;
  }

  static Future<int> countMaintainRooms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    int total = 0;

    final hostels = await FirebaseFirestore.instance
        .collection("hostels")
        .where("ownerId", isEqualTo: user.uid)
        .get();

    for (var h in hostels.docs) {
      final roomsSnap = await FirebaseFirestore.instance
          .collection("hostels")
          .doc(h.id)
          .collection("rooms")
          .where("status", isEqualTo: "maintain")
          .get();

      total += roomsSnap.size;
    }

    return total;
  }
}
