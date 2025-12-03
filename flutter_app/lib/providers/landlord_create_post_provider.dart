// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../models/room.dart';
// import '../services/cloudinary_service.dart';

// class LandlordCreatePostProvider with ChangeNotifier {
//   final formKey1 = GlobalKey<FormState>();
//   final formKey2 = GlobalKey<FormState>();
//   final formKey3 = GlobalKey<FormState>();

//   int currentStep = 0;
//   bool isLoading = false;
//   bool isUploadingImages = false;

//   final titleControler = TextEditingController();
//   final floorController = TextEditingController();
//   final addressController = TextEditingController();
//   final roomNumberController = TextEditingController();
//   final areaController = TextEditingController();
//   final capacityController = TextEditingController();
//   final currentResidentsController = TextEditingController();
//   final priceController = TextEditingController();
//   final descriptionController = TextEditingController();

//   String roomType = 'Phòng đơn';
//   String pricingType = 'per_room';
//   bool includesUtilities = false;

//   List<XFile> selectedImages = [];
//   List<String> imageUrls = [];

//   List<String> selectedAmenities = [];
//   List<String> selectedFurniture = [];

//   void nextStep() {
//     if (currentStep < 2) {
//       currentStep++;
//       notifyListeners();
//     }
//   }

//   void previousStep() {
//     if (currentStep > 0) {
//       currentStep--;
//       notifyListeners();
//     }
//   }

//   void addLocalImages(List<XFile> images) {
//     final remaining = 15 - selectedImages.length;
//     selectedImages.addAll(images.take(remaining));
//     notifyListeners();
//   }

//   void removeImageAt(int index) {
//     if (index < 0 || index >= selectedImages.length) return;
//     selectedImages.removeAt(index);
//     if (index < imageUrls.length) imageUrls.removeAt(index);
//     notifyListeners();
//   }

//   Future<bool> uploadImageFileAt(int index) async {
//     if (index >= selectedImages.length) return false;
//     isUploadingImages = true;
//     notifyListeners();

//     final url = await CloudinaryService.uploadFile(selectedImages[index].path);
//     isUploadingImages = false;

//     if (url != null) {
//       if (index < imageUrls.length) {
//         imageUrls[index] = url;
//       } else {
//         imageUrls.add(url);
//       }
//       notifyListeners();
//       return true;
//     }
//     notifyListeners();
//     return false;
//   }

//   Future<bool> uploadAllImages() async {
//     imageUrls.clear();
//     isUploadingImages = true;
//     notifyListeners();

//     for (final image in selectedImages) {
//       final url = await CloudinaryService.uploadFile(image.path);
//       if (url == null) {
//         isUploadingImages = false;
//         notifyListeners();
//         return false;
//       }
//       imageUrls.add(url);
//     }

//     isUploadingImages = false;
//     notifyListeners();
//     return true;
//   }

//   Future<Room?> buildTempRoom() async {
//     if (formKey1.currentState == null || 
//         formKey2.currentState == null || 
//         !formKey1.currentState!.validate() || 
//         !formKey2.currentState!.validate() || 
//         selectedImages.isEmpty) {
//       return null;
//     }

//     if (imageUrls.length != selectedImages.length) {
//       final ok = await uploadAllImages();
//       if (!ok) return null;
//     }

//     return Room(
//       id: '',
//       hostelId: '',
//       ownerId: '',
//       title: titleControler.text.trim(),
//       address: addressController.text.trim(),
//       roomNumber: roomNumberController.text.trim().isNotEmpty
//           ? roomNumberController.text.trim()
//           : 'P${floorController.text}',
//       description: descriptionController.text.trim(),
//       genderRequirement: 'Không yêu cầu',
//       price: double.tryParse(priceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
//       pricingType: pricingType,
//       includesUtilities: includesUtilities,
//       roomType: roomType,
//       floor: int.tryParse(floorController.text) ?? 1,
//       area: double.tryParse(areaController.text) ?? 20.0,
//       capacity: int.tryParse(capacityController.text) ?? 2,
//       currentResidents: int.tryParse(currentResidentsController.text) ?? 0,
//       amenities: selectedAmenities,
//       furniture: selectedFurniture,
//       images: imageUrls,
//       status: 'available',
//       createdAt: DateTime.now(),
//     );
//   }

//   Future<bool> createPost(BuildContext context) async {
//     final room = await buildTempRoom();
//     if (room == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin và ảnh')),
//       );
//       return false;
//     }

//     isLoading = true;
//     notifyListeners();

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) throw Exception('Chưa đăng nhập');

//       final roomRef = FirebaseFirestore.instance.collection('rooms').doc();
//       await roomRef.set(room.copyWith(
//         id: roomRef.id,
//         ownerId: user.uid,
//       ).toMap());

//       reset();
//       isLoading = false;
//       notifyListeners();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Đăng tin thành công!')),
//       );
//       return true;
//     } catch (e) {
//       isLoading = false;
//       notifyListeners();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Lỗi: $e')),
//       );
//       return false;
//     }
//   }

//   void reset() {
//     currentStep = 0;
//     titleControler.clear();
//     floorController.clear();
//     addressController.clear();
//     roomNumberController.clear();
//     areaController.clear();
//     capacityController.clear();
//     currentResidentsController.clear();
//     priceController.clear();
//     descriptionController.clear();
//     selectedAmenities.clear();
//     selectedFurniture.clear();
//     selectedImages.clear();
//     imageUrls.clear();
//     roomType = 'Phòng đơn';
//     pricingType = 'per_room';
//     includesUtilities = false;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     titleControler.dispose();
//     floorController.dispose();
//     addressController.dispose();
//     roomNumberController.dispose();
//     areaController.dispose();
//     capacityController.dispose();
//     currentResidentsController.dispose();
//     priceController.dispose();
//     descriptionController.dispose();
//     super.dispose();
//   }
// }