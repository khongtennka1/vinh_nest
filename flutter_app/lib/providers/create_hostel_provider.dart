import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';
import '../models/hostel.dart';

class CreateHostelProvider with ChangeNotifier {
  final formKey1 = GlobalKey<FormState>();

  int currentStep = 0;

  final nameController = TextEditingController();
  final cityController = TextEditingController();
  final wardController = TextEditingController();
  final streetController = TextEditingController();
  final parkingController = TextEditingController();
  final descriptionController = TextEditingController();

  List<XFile> selectedImages = [];
  List<String> imageUrls = [];

  List<String> selectedFacilities = [];
  List<String> selectedInteriors = [];
  List<String> selectedRoomTypes = [];

  bool isLoading = false;
  bool isUploadingImages = false;

  final List<String> allFacilities = [
  'Wifi',
  'Bếp',
  'Ban công',
  "Gửi xe điện",
  "Nội thất",
  "Điều hòa",
  "Nóng lạnh",
  "Kệ bếp",
  "Tủ lạnh",
  "Giường ngủ",
  "Máy giặt",
  "Đồ dùng bếp",
  'Gác lửng',
  'Thang máy',
  'Bảo vệ',
  'Camera',
  'Chỗ để xe',
  'Tự do giờ giấc'
  ];

  final List<String> allInteriors = [
  "Bàn ghế",
  "Đèn trang trí",
  "Tranh trang trí",
  "Cây cối trang trí",
  "Chăn ga gối",
  "Tủ quần áo",
  "Nệm",
  "Kệ giày dép",
  "Rèm",
  "Quạt trần",
  "Gương toàn thân",
  "Sofa"
  ];

  final List<String> allRoomTypes= [
    'Phòng trọ',
    'Chung cư',
    'Chung cư mini',
    'Homestay',
    'Ký túc xá',
    'Khác'
  ];

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

  void addImages(List<XFile> images) {
    selectedImages.addAll(images);
    notifyListeners();
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
    if (index < imageUrls.length) imageUrls.removeAt(index);
    notifyListeners();
  }

  Future<bool> uploadAllImages() async {
    if (selectedImages.isEmpty) return true;

    isUploadingImages = true;
    notifyListeners();

    imageUrls.clear();
    for (var file in selectedImages) {
      final url = await CloudinaryService.uploadFile(file.path);
      if (url == null) {
        isUploadingImages = false;
        notifyListeners();
        return false;
      }
      imageUrls.add(url);
      notifyListeners();
    }

    isUploadingImages = false;
    notifyListeners();
    return true;
  }

  Future<bool> createHostel(BuildContext context) async {
    if (!formKey1.currentState!.validate()) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập!')),
      );
      return false;
    }

    if (imageUrls.length != selectedImages.length) {
      final ok = await uploadAllImages();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload ảnh thất bại!')),
        );
        return false;
      }
    }

    isLoading = true;
    notifyListeners();

    try {
      final fullAddress = '${streetController.text.trim()}, ${wardController.text.trim()}, ${cityController.text.trim()}';

      final hostelRef = FirebaseFirestore.instance.collection('hostels').doc();
      final hostel = Hostel(
        id: hostelRef.id,
        ownerId: user.uid,
        name: nameController.text.trim(),
        addressId: fullAddress,  
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        facilities: selectedFacilities,
        interiors: selectedInteriors,
        roomTypes: selectedRoomTypes,
        images: imageUrls,
        numberParkingSpaces: int.tryParse(parkingController.text) ?? 0,
        services: [], 
        createdAt: DateTime.now(),
        status: 'active',
      );

      await hostelRef.set(hostel.toMap());

      _reset();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _reset() {
    currentStep = 0;
    nameController.clear();
    cityController.clear();
    wardController.clear();
    streetController.clear();
    parkingController.clear();
    descriptionController.clear();
    selectedImages.clear();
    imageUrls.clear();
    selectedFacilities.clear();
    selectedInteriors.clear();
    selectedRoomTypes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    cityController.dispose();
    wardController.dispose();
    streetController.dispose();
    parkingController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}