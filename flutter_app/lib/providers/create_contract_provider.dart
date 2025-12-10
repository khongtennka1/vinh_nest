import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'package:room_rental_app/services/cloudinary_service.dart';
import 'package:room_rental_app/models/hostel.dart';
import 'package:room_rental_app/models/room.dart';

class CreateContractProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  final formKey3 = GlobalKey<FormState>();
  final formKey4 = GlobalKey<FormState>();

  bool isLoading = false;
  bool isUploadingImages = false;
  bool loadingHostels = true;
  bool loadingRooms = false;

  Hostel? selectedHostel;
  Room? selectedRoom;

  List<Hostel> myHostels = [];
  List<Room> roomsInSelectedHostel = [];

  final tenantNameController = TextEditingController();
  final tenantPhoneController = TextEditingController();
  final tenantEmailController = TextEditingController();
  final tenantIdNumberController = TextEditingController();
  final monthlyRentController = TextEditingController();
  final depositController = TextEditingController();
  final serviceNameController = TextEditingController();
  final servicePriceController = TextEditingController();
  final noteController = TextEditingController();

  List<XFile> tenantIdImages = [];
  List<String> tenantIdUrls = [];
  List<XFile> contractImages = [];
  List<String> contractUrls = [];

  List<String> additionalMembers = [];
  List<Map<String, dynamic>> services = [];
  List<String> interiorItems = [];

  DateTime? startDate;
  DateTime? endDate;
  DateTime? rentStartCalcDate;

  String paymentCycle = 'Hàng tháng';
  final List<String> paymentCycles = [
    'Hàng tháng',
    '3 tháng/lần',
    '6 tháng/lần',
    '1 năm/lần'
  ];

  CreateContractProvider() {
    loadMyHostels();
  }
 
  Future<void> loadMyHostels() async {
    if (currentUser == null) return;

    loadingHostels = true;
    notifyListeners();

    try {
      final snap = await _db
          .collection('hostels')
          .where('ownerId', isEqualTo: currentUser!.uid)
          .get();

      myHostels = snap.docs
          .map((doc) => Hostel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Lỗi load hostels: $e');
    } finally {
      loadingHostels = false;
      notifyListeners();
    }
  }

  Future<void> loadRoomsInHostel(String hostelId) async {
    loadingRooms = true;
    notifyListeners();

    try {
      final snap = await _db
          .collection('hostels')
          .doc(hostelId)
          .collection('rooms')
          .where('status', isEqualTo: 'available')
          .get();

      roomsInSelectedHostel = snap.docs
          .map((doc) => Room.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Lỗi load rooms: $e');
    } finally {
      loadingRooms = false;
      notifyListeners();
    }
  }

  void updateMonthlyRent() {
    if (selectedRoom == null) return;

    final int totalPeople = additionalMembers.length + 1; 
    double rent = selectedRoom!.price;

    if (selectedRoom!.pricingType == 'per_person') {
      rent = selectedRoom!.price * totalPeople;
    }

    monthlyRentController.text = NumberFormat('#,##0').format(rent.toInt());
    notifyListeners();
  }

  void addService() {
    if (serviceNameController.text.trim().isEmpty ||
        servicePriceController.text.trim().isEmpty) return;

    final priceText = servicePriceController.text.replaceAll(RegExp(r'[.,]'), '');
    final price = double.tryParse(priceText) ?? 0;
    if (price <= 0) return;

    services.add({
      'name': serviceNameController.text.trim(),
      'price': price,
    });

    serviceNameController.clear();
    servicePriceController.clear();
    notifyListeners();
  }

  void removeService(int index) {
    if (index >= 0 && index < services.length) {
      services.removeAt(index);
      notifyListeners();
    }
  }

  void pickTenantIdImages(List<XFile> images) {
    tenantIdImages
      ..clear()
      ..addAll(images.take(2));
    notifyListeners();
  }

  void pickContractImages(List<XFile> images) {
    contractImages.addAll(images);
    notifyListeners();
  }

  void removeTenantIdImage(int index) {
    if (index >= 0 && index < tenantIdImages.length) {
      tenantIdImages.removeAt(index);
      if (index < tenantIdUrls.length) {
        tenantIdUrls.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeContractImage(int index) {
    if (index >= 0 && index < contractImages.length) {
      contractImages.removeAt(index);
      if (index < contractUrls.length) {
        contractUrls.removeAt(index);
      }
      notifyListeners();
    }
  }

  Future<String?> _uploadSingle(XFile file) async {
    try {
      return await CloudinaryService.uploadFile(file.path);
    } catch (e) {
      debugPrint('Upload lỗi: $e');
      return null;
    }
  }

  Future<bool> uploadAllImages() async {
    isUploadingImages = true;
    notifyListeners();

    tenantIdUrls.clear();
    contractUrls.clear();

    try {
      for (final img in tenantIdImages) {
        final url = await _uploadSingle(img);
        if (url == null) return false;
        tenantIdUrls.add(url);
      }
      for (final img in contractImages) {
        final url = await _uploadSingle(img);
        if (url == null) return false;
        contractUrls.add(url);
      }
      return true;
    } catch (e) {
      debugPrint('Upload all lỗi: $e');
      return false;
    } finally {
      isUploadingImages = false;
      notifyListeners();
    }
  }

  Future<bool> createContract(BuildContext context) async {
    if (selectedHostel == null ||
        selectedRoom == null ||
        startDate == null ||
        endDate == null ||
        rentStartCalcDate == null ||
        tenantNameController.text.trim().isEmpty ||
        tenantPhoneController.text.trim().isEmpty ||
        tenantIdNumberController.text.trim().isEmpty ||
        tenantIdImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin bắt buộc và chọn đủ 2 ảnh CMND!'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      if (tenantIdUrls.length != tenantIdImages.length ||
          contractUrls.length != contractImages.length) {
        final success = await uploadAllImages();
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload ảnh thất bại!'), backgroundColor: Colors.red),
          );
          return false;
        }
      }

      final data = {
        'hostelId': selectedHostel!.id,
        'roomId': selectedRoom!.id,
        'landlordId': currentUser!.uid,
        'tenantName': tenantNameController.text.trim(),
        'tenantPhone': tenantPhoneController.text.trim(),
        'tenantEmail': tenantEmailController.text.trim().isEmpty ? null : tenantEmailController.text.trim(),
        'tenantIdNumber': tenantIdNumberController.text.trim(),
        'tenantIdImages': tenantIdUrls,
        'roomNumber': selectedRoom!.roomNumber,
        'hostelName': selectedHostel!.name,
        'additionalMembers': additionalMembers,
        'startDate': Timestamp.fromDate(startDate!),
        'endDate': Timestamp.fromDate(endDate!),
        'monthlyRent': double.parse(monthlyRentController.text.replaceAll(RegExp(r'[.,]'), '')),
        'deposit': depositController.text.trim().isEmpty
            ? 0
            : double.parse(depositController.text.replaceAll(RegExp(r'[.,]'), '')),
        'rentStartCalcDate': Timestamp.fromDate(rentStartCalcDate!),
        'paymentCycle': paymentCycle,
        'services': services,
        'interiorItems': interiorItems,
        'contractImages': contractUrls,
        'note': noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      final docRef = await _db.collection('contracts').add(data);
      await docRef.update({'id': docRef.id});

      await _db
          .collection('hostels')
          .doc(selectedHostel!.id)
          .collection('rooms')
          .doc(selectedRoom!.id)
          .update({'status': 'rented', 'isAvailable': false});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo hợp đồng thành công!'), backgroundColor: Colors.green),
      );

      _resetAll();
      return true;
    } catch (e) {
      debugPrint('Lỗi tạo hợp đồng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _resetAll() {
    selectedHostel = null;
    selectedRoom = null;
    roomsInSelectedHostel.clear();

    tenantNameController.clear();
    tenantPhoneController.clear();
    tenantEmailController.clear();
    tenantIdNumberController.clear();
    monthlyRentController.clear();
    depositController.clear();
    noteController.clear();
    serviceNameController.clear();
    servicePriceController.clear();

    tenantIdImages.clear();
    tenantIdUrls.clear();
    contractImages.clear();
    contractUrls.clear();
    additionalMembers.clear();
    services.clear();
    interiorItems.clear();

    startDate = null;
    endDate = null;
    rentStartCalcDate = null;
    paymentCycle = 'Hàng tháng';

    notifyListeners();
  }

  @override
  void dispose() {
    tenantNameController.dispose();
    tenantPhoneController.dispose();
    tenantEmailController.dispose();
    tenantIdNumberController.dispose();
    monthlyRentController.dispose();
    depositController.dispose();
    serviceNameController.dispose();
    servicePriceController.dispose();
    noteController.dispose();
    super.dispose();
  }
}