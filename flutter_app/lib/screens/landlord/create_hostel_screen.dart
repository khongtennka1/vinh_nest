import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/create_hostel_provider.dart';

class CreateHostelScreen extends StatelessWidget {
  const CreateHostelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateHostelProvider(),
      child: const _CreateHostelView(),
    );
  }
}

class _CreateHostelView extends StatelessWidget {
  const _CreateHostelView();

  final List<String> allFacilities = const [
  'Wifi',
  'Ra vào bằng vân tay',
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

  final List<String> allInteriors = const [
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

  final List<String> allRoomTypes= const [
    'Phòng trọ',
    'Chung cư',
    'Chung cư mini',
    'Homestay',
    'Ký túc xá',
    'Khác'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<CreateHostelProvider>(
      builder: (context, p, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Tạo toà nhà mới', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: IndexedStack(
            index: p.currentStep,
            children: [
              _stepInfo(p),
              _stepImages(p),
              _stepFacilities(p),
            ],
          ),
          bottomNavigationBar: _bottomBar(context, p),
        );
      },
    );
  }

  Widget _stepInfo(CreateHostelProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: p.formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin toà nhà', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 20),
            _field(p.nameController, 'Tên toà nhà *', 'VD: KTX Đại học Vinh', Icons.home, validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
            const SizedBox(height: 16),
            _field(p.cityController, 'Tỉnh/Thành phố *', 'VD: Vinh', Icons.location_city, validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
            const SizedBox(height: 16),
            _field(p.wardController, 'Quận/Huyện *', 'VD: Trường Vinh', Icons.maps_home_work, validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
            const SizedBox(height: 16),
            _field(p.streetController, 'Đường/Số nhà *', 'VD: Lê Duẩn', Icons.streetview, validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),

            const SizedBox(height: 30),

            const Text('Loại phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20,),

            Wrap(
            spacing: 10,
            runSpacing: 10,
            children: p.allRoomTypes.map((item) {
              final selected = p.selectedRoomTypes.contains(item);
              return FilterChip(
                label: Text(item),
                selected: selected,
                onSelected: (_) {
                  if (selected) {
                    p.selectedRoomTypes.remove(item);
                  } else {
                    p.selectedRoomTypes.add(item);
                  }
                  p.notifyListeners();
                },
                selectedColor: Colors.orange,
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              );
            }).toList(),
          ),
          ],
        ),
      ),
    );
  }

  Widget _stepImages(CreateHostelProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ảnh toà nhà (tối thiểu 1 ảnh)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (p.selectedImages.isNotEmpty)
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: p.selectedImages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(p.selectedImages[i].path), width: 130, height: 130, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => p.removeImage(i),
                          child: const CircleAvatar(radius: 14, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final picker = ImagePicker();
              final imgs = await picker.pickMultiImage();
              if (imgs.isNotEmpty) p.addImages(imgs);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 50),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_a_photo, size: 50, color: Colors.orange),
                  SizedBox(height: 12),
                  Text('Thêm ảnh toà nhà', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                  Text('Tối đa 10 ảnh', style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepFacilities(CreateHostelProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(p.parkingController, 'Số chỗ để xe (tuỳ chọn)', 'VD: 30', Icons.local_parking),
          const SizedBox(height: 30),
          const Text('Tiện ích chung của toà nhà', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: p.allFacilities.map((item) {
              final selected = p.selectedFacilities.contains(item);
              return FilterChip(
                label: Text(item),
                selected: selected,
                onSelected: (_) {
                  if (selected) {
                    p.selectedFacilities.remove(item);
                  } else {
                    p.selectedFacilities.add(item);
                  }
                  p.notifyListeners();
                },
                selectedColor: Colors.orange,
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),

          const Text('Nội thất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: p.allInteriors.map((item) {
              final selected = p.selectedInteriors.contains(item);
              return FilterChip(
                label: Text(item),
                selected: selected,
                onSelected: (_) {
                  if (selected) {
                    p.selectedInteriors.remove(item);
                  } else {
                    p.selectedInteriors.add(item);
                  }
                  p.notifyListeners();
                },
                selectedColor: Colors.orange,
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),
          _field(p.descriptionController, 'Mô tả toà nhà (tuỳ chọn)', 'Giới thiệu, quy định...', Icons.description, maxLines: 6),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, CreateHostelProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        children: [
          if (p.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: p.previousStep,
                child: const Text('Quay lại'),
              ),
            ),
          if (p.currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: p.isLoading ? null : () async {
                if (p.currentStep < 2) {
                  if (p.currentStep == 0 && !(p.formKey1.currentState?.validate() ?? false)) return;
                  if (p.currentStep == 1 && p.selectedImages.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm ít nhất 1 ảnh!')));
                    return;
                  }
                  p.nextStep();
                } else {
                  final success = await p.createHostel(context);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo toà nhà thành công! Bạn có thể thêm phòng sau'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: p.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(p.currentStep == 2 ? 'Hoàn tất tạo toà' : 'Tiếp tục'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint, IconData icon, {String? Function(String?)? validator, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.orange),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}