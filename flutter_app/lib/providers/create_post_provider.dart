import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostProvider with ChangeNotifier {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  GlobalKey<FormState> get formKey1 => _formKey1;
  GlobalKey<FormState> get formKey2 => _formKey2;
  GlobalKey<FormState> get formKey3 => _formKey3;

  int currentStep = 0;

  String roomType = 'Phòng đơn';
  final floorController = TextEditingController();
  final areaController = TextEditingController();
  final capacityController = TextEditingController();
  final currentResidentsController = TextEditingController();
  final moveInDateController = TextEditingController();
  final priceController = TextEditingController();
  String pricingType = 'per_person';
  bool includesUtilities = false;

  List<String> selectedAmenities = [];
  List<String> selectedFurniture = [];
  final descriptionController = TextEditingController();

  List<XFile> selectedImages = [];

  bool isLoading = false;

  void nextStep() {
    if (currentStep < 2) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  Future<bool> createPost() async {
  if (currentStep == 0 && !_formKey1.currentState!.validate()) return false;
  if (currentStep == 1 && !_formKey2.currentState!.validate()) return false;
  if (currentStep == 2 && selectedImages.isEmpty) {
    return false;
  }

  isLoading = true;
  notifyListeners();

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw "Không tìm thấy người dùng";

    final hostelRef = FirebaseFirestore.instance.collection('hostels').doc();
    final roomRef = hostelRef.collection('rooms').doc();

    final storage = FirebaseStorage.instance;
    List<String> imageUrls = [];

    for (final img in selectedImages) {
      final file = File(img.path);
      Text('Uploading: ${img.path}');
      Text('Exists: ${await file.exists()}');

      if (!await file.exists()) {
        throw "File không tồn tại hoặc không truy cập được: ${img.path}";
      }

      final ref = storage.ref().child(
        'room_images/${roomRef.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      imageUrls.add(url);
    }

    final hostel = {
      'id': hostelRef.id,
      'ownerId': user.uid,
      'name': '$roomType - ${areaController.text} m²',
      'addressId': 'temp_address',
      'description': descriptionController.text,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final room = {
      'id': roomRef.id,
      'hostelId': hostelRef.id,
      'roomNumber': 'P${floorController.text}',
      'floor': int.tryParse(floorController.text) ?? 1,
      'area': double.tryParse(areaController.text) ?? 0,
      'capacity': int.tryParse(capacityController.text) ?? 1,
      'currentResidents': int.tryParse(currentResidentsController.text) ?? 0,
      'moveInDate': moveInDateController.text,
      'price': double.tryParse(priceController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0,
      'pricingType': pricingType,
      'includesUtilities': includesUtilities,
      'amenities': selectedAmenities,
      'furniture': selectedFurniture,
      'description': descriptionController.text,
      'images': imageUrls, 
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await hostelRef.set(hostel);
    await roomRef.set(room);

    _reset();
    isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    print('Lỗi khi tạo bài đăng: $e');
    isLoading = false;
    notifyListeners();
    return false;
  }
}

  void _reset() {
    currentStep = 0;
    floorController.clear();
    areaController.clear();
    capacityController.clear();
    currentResidentsController.clear();
    moveInDateController.clear();
    priceController.clear();
    descriptionController.clear();
    selectedAmenities.clear();
    selectedFurniture.clear();
    selectedImages.clear();
  }

  @override
  void dispose() {
    floorController.dispose();
    areaController.dispose();
    capacityController.dispose();
    currentResidentsController.dispose();
    moveInDateController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}