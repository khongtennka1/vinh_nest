import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/hostel.dart';
import '../models/address.dart';

class RoomProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Room> _availableRooms = [];
  List<Room> get availableRooms => _availableRooms;

  Stream<List<Map<String, dynamic>>> getAvailableRoomPosts() {
    return _db
        .collectionGroup('rooms') 
        .where('status', isEqualTo: 'available')
        .snapshots()
        .asyncMap((roomSnap) async {
      List<Map<String, dynamic>> posts = [];

      for (var roomDoc in roomSnap.docs) {
        final data = roomDoc.data();
        final roomId = roomDoc.id;
        final hostelId = roomDoc.reference.parent.parent!.id; 

        final room = Room.fromMap(data, roomId);

        final hostelDoc = await _db.collection('hostels').doc(hostelId).get();
        if (!hostelDoc.exists) continue;
        final hostel = Hostel.fromMap(hostelDoc.data()!, hostelId);

        Address? address;
        if (hostel.addressId.isNotEmpty) {
          final addressDoc = await _db.collection('addresses').doc(hostel.addressId).get();
          if (addressDoc.exists) {
            address = Address.fromMap(addressDoc.data()!, addressDoc.id);
          }
        }

        posts.add({
          'room': room,
          'hostel': hostel,
          'address': address,
        });
      }
      return posts;
    });
  }
}