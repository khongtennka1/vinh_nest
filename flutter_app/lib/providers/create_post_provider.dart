import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';

class CreatePostProvider with ChangeNotifier {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  GlobalKey<FormState> get formKey1 => _formKey1;
  GlobalKey<FormState> get formKey2 => _formKey2;
  GlobalKey<FormState> get formKey3 => _formKey3;

  int currentStep = 0;

  final titleControler = TextEditingController();
  String roomType = 'Phòng đơn';
  final floorController = TextEditingController();
  final addressController = TextEditingController();
  final areaController = TextEditingController();
  final roomNumberController = TextEditingController();
  final descriptionController = TextEditingController();
  final capacityController = TextEditingController();
  final currentResidentsController = TextEditingController();
  final priceController = TextEditingController();

  String pricingType = 'per_person';
  bool includesUtilities = false;

  List<XFile> selectedImages = []; 
  List<String> imageUrls = []; 

  List<String> selectedAmenities = [];
  List<String> selectedFurniture = [];

  bool isLoading = false; 
  bool isUploadingImages = false;

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

  void addLocalImages(List<XFile> images) {
    selectedImages.addAll(images);
    notifyListeners();
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    selectedImages.removeAt(index);
    if (index < imageUrls.length) {
      imageUrls.removeAt(index);
    }
    notifyListeners();
  }

  Future<bool> uploadImageFileAt(int index) async {
    if (index < 0 || index >= selectedImages.length) return false;
    isUploadingImages = true;
    notifyListeners();
    final path = selectedImages[index].path;
    final url = await CloudinaryService.uploadFile(path);
    isUploadingImages = false;
    if (url != null) {
      if (index <= imageUrls.length - 1) {
        imageUrls[index] = url;
      } else {
        imageUrls.add(url);
      }
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAllImages() async {
    imageUrls = [];
    isUploadingImages = true;
    notifyListeners();

    for (int i = 0; i < selectedImages.length; i++) {
      final path = selectedImages[i].path;
      final url = await CloudinaryService.uploadFile(path);
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

  Future<bool> createPost(BuildContext context) async {
    if (currentStep == 0 && !_formKey1.currentState!.validate()) return false;
    if (currentStep == 1 && !_formKey2.currentState!.validate()) return false;
    if (currentStep == 2 && selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ảnh')),
      );
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Bạn cần đăng nhập để đăng tin!");
      }

      if (imageUrls.length != selectedImages.length) {
        final ok = await uploadAllImages();
        if (!ok) throw Exception('Upload ảnh thất bại');
      }

      final hostelRef = FirebaseFirestore.instance.collection('hostels').doc();
      await hostelRef.set({
        'id': hostelRef.id,
        'ownerId': user.uid,
        'name': '$roomType - ${areaController.text} m²',
        'addressId': 'temp_address',
        'description': descriptionController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final roomRef = hostelRef.collection('rooms').doc();
      await roomRef.set({
        'id': roomRef.id,
        'hostelId': hostelRef.id,
        'ownerId': user.uid,
        'title': titleControler.text.trim(),
        'address': addressController.text.trim(),
        'roomType': roomType,
        'roomNumber': roomNumberController.text.trim().isEmpty
            ? 'P${floorController.text}'
            : roomNumberController.text.trim(),
        'floor': int.tryParse(floorController.text) ?? 1,
        'area': double.tryParse(areaController.text) ?? 20.0,
        'capacity': int.tryParse(capacityController.text) ?? 2,
        'currentResidents': int.tryParse(currentResidentsController.text) ?? 0,
        'price': double.tryParse(priceController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0,
        'pricingType': pricingType,
        'includesUtilities': includesUtilities,
        'amenities': selectedAmenities,
        'furniture': selectedFurniture,
        'description': descriptionController.text.trim(),
        'images': imageUrls,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _reset();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Đăng tin lỗi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng tin thất bại: $e')),
      );
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _reset() {
    currentStep = 0;
    titleControler.clear();
    addressController.clear();
    roomNumberController.clear();
    floorController.clear();
    areaController.clear();
    capacityController.clear();
    currentResidentsController.clear();
    priceController.clear();
    descriptionController.clear();
    selectedAmenities.clear();
    selectedFurniture.clear();
    selectedImages.clear();
    imageUrls.clear();
    roomType = 'Phòng đơn';
    pricingType = 'per_person';
    includesUtilities = false;
  }

  @override
  void dispose() {
    titleControler.dispose();
    addressController.dispose();
    roomNumberController.dispose();
    floorController.dispose();
    areaController.dispose();
    capacityController.dispose();
    currentResidentsController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}