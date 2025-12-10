
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/hostel.dart';
import '../models/address.dart';

class RoomProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getAvailableRoomPosts() {
    return _db
        .collectionGroup('rooms')
        .where('status', isEqualTo: 'available') 
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> result = [];

      for (var roomDoc in querySnapshot.docs) {
        try {
          final roomData = roomDoc.data();
          final roomId = roomDoc.id;
          final hostelId = roomDoc.reference.parent.parent!.id;

          final room = Room.fromMap({...roomData, 'id': roomId}, roomId);

          final hostelDoc = await _db.collection('hostels').doc(hostelId).get();
          Hostel hostel;
          if (hostelDoc.exists) {
            hostel = Hostel.fromMap(hostelDoc.data()!, hostelId);
          } else {
            hostel = Hostel(
              id: hostelId,
              ownerId: '',
              name: 'Toà nhà không xác định',
              addressId: '',
              numberParkingSpaces: 0,
              roomTypes: ['Phòng trọ'],
              createdAt: DateTime.now(),
              customServices: [],
            );
          }

          Address? address;
          final String addressId = hostel.addressId;

          if (addressId.isNotEmpty) {
            try {
              final addressDoc = await _db.collection('addresses').doc(addressId).get();
              if (addressDoc.exists) {
                address = Address.fromMap(addressDoc.data()!, addressDoc.id);
              }
            } catch (e) {
              debugPrint('Lỗi lấy địa chỉ $addressId: $e');
              address = null;
            }
          }

          result.add({
            'room': room,
            'hostel': hostel,
            'address': address, 
          });
        } catch (e) {
          debugPrint('Lỗi xử lý phòng ${roomDoc.id}: $e');
          continue;
        }
      }

      return result;
    });
  }

  // Stream<List<Map<String, dynamic>>> getMyRooms(String ownerId) {
  //   return _db
  //       .collectionGroup('rooms')
  //       .where('ownerId', isEqualTo: ownerId)
  //       .snapshots()
  //       .asyncMap((querySnapshot) async {
  //     List<Map<String, dynamic>> result = [];

  //     for (var roomDoc in querySnapshot.docs) {
  //       try {
  //         final roomData = roomDoc.data();
  //         final roomId = roomDoc.id;
  //         final hostelId = roomDoc.reference.parent.parent!.id;

  //         final room = Room.fromMap(roomData, roomId);

  //         final hostelDoc = await _db.collection('hostels').doc(hostelId).get();
  //         Hostel hostel;

  //         if (hostelDoc.exists) {
  //           hostel = Hostel.fromMap(hostelDoc.data()!, hostelId);
  //         } else {
  //           hostel = Hostel(
  //             id: hostelId,
  //             ownerId: ownerId,
  //             name: 'Toà nhà không xác định',
  //             addressId: '',
  //             numberParkingSpaces: 0,
  //             roomTypes: ['Phòng trọ'],
  //             createdAt: DateTime.now(),
  //             customServices: [], 
  //           );
  //         }

  //         Address? address;
  //         if (hostel.addressId.isNotEmpty) {
  //           try {
  //             final addrDoc = await _db.collection('addresses').doc(hostel.addressId).get();
  //             if (addrDoc.exists) {
  //               address = Address.fromMap(addrDoc.data()!, addrDoc.id);
  //             }
  //           } catch (e) {
  //             debugPrint('Lỗi lấy địa chỉ: $e');
  //           }
  //         }

  //         result.add({
  //           'room': room,
  //           'hostel': hostel,
  //           'address': address,
  //         });
  //       } catch (e) {
  //         debugPrint('Lỗi load phòng của tôi: $e');
  //       }
  //     }

  //     return result;
  //   });
  // }
}