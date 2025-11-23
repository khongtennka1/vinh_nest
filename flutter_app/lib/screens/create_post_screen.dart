import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/create_post_provider.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostProvider(),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatelessWidget {
  const _CreatePostView();

  @override
  Widget build(BuildContext context) {
    return Consumer<CreatePostProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Tạo bài đăng - Bước ${provider.currentStep + 1}/3'),
            centerTitle: true,
          ),
          body: _buildStep(provider, context),
          bottomNavigationBar: _buildBottomBar(provider, context),
        );
      },
    );
  }

  Widget _buildStep(CreatePostProvider provider, BuildContext context) {
    switch (provider.currentStep) {
      case 0:
        return Step1(provider: provider);
      case 1:
        return Step2(provider: provider);
      case 2:
        return Step3(provider: provider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomBar(CreatePostProvider provider, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (provider.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: provider.previousStep,
                child: const Text('Quay lại'),
              ),
            ),
          if (provider.currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (provider.currentStep < 2) {
                        if ((provider.currentStep == 0 && provider.formKey1.currentState!.validate()) ||
                            (provider.currentStep == 1 && provider.formKey2.currentState!.validate())) {
                          provider.nextStep();
                        }
                      } else {
                        final success = await provider.createPost();
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đăng tin thành công!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(provider.currentStep == 2 ? 'Đăng tin' : 'Tiếp theo'),
            ),
          ),
        ],
      ),
    );
  }
}

class Step1 extends StatelessWidget {
  final CreatePostProvider provider;
  const Step1({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: provider.formKey1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 16),

             _buildTextField(
              controller: provider.floorController,
              label: 'Tiêu đề *',
              hint: 'Nhập tiêu đề',
              icon: Icons.title,
              keyboardType: TextInputType.text,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Loại phòng *',
              value: provider.roomType,
              items: ['Phòng đơn', 'Phòng đôi', 'Phòng ghép', 'Căn hộ'],
              icon: Icons.home,
              onChanged: (v) => provider.roomType = v!,
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: provider.floorController,
              label: 'Tầng *',
              hint: 'Nhập tầng',
              icon: Icons.stairs,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập tầng' : null,
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: provider.areaController,
              label: 'Diện tích (m²) *',
              hint: 'Nhập diện tích',
              icon: Icons.square_foot,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập diện tích' : null,
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: provider.capacityController,
              label: 'Sức chứa (người/phòng) *',
              hint: 'Nhập số người',
              icon: Icons.people,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Vui lòng nhập sức chứa';
                }
                return null; 
              },
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: provider.currentResidentsController,
              label: 'Số người hiện tại *',
              hint: 'Nhập số người',
              icon: Icons.person,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập số người';
                final current = int.tryParse(v);
                final capacityText = provider.capacityController.text;
                if (capacityText.isEmpty) return 'Vui lòng nhập sức chứa trước';
                final capacity = int.tryParse(capacityText);
                if (current == null) return 'Số không hợp lệ';
                if (capacity == null) return 'Sức chứa không hợp lệ';
                if (current > capacity) {
                  return 'Không thể vượt quá sức chứa ($capacity người)';
                }
                return null;
              }
            ),

            const SizedBox(height: 16),
            _buildDateField(provider, context),

            const SizedBox(height: 24),
            const Text('Tiền phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),

            const SizedBox(height: 16),
            _buildTextField(
              controller: provider.priceController,
              label: 'Giá thuê (VND/tháng) *',
              hint: 'Nhập số tiền',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập giá' : null,
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildRadio('Theo đầu người', 'per_person', provider)),
                Expanded(child: _buildRadio('Theo phòng', 'per_room', provider)),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(CreatePostProvider provider, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ngày chuyển vào *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: provider.moveInDateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'dd/mm/yyyy',
            prefixIcon: const Icon(Icons.calendar_today, color: Colors.orange),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => v!.isEmpty ? 'Vui lòng chọn ngày' : null,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              provider.moveInDateController.text = '${date.day}/${date.month}/${date.year}';
            }
          },
        ),
      ],
    );
  }
}

class Step2 extends StatelessWidget {
  final CreatePostProvider provider;
  Step2({required this.provider});

  final List<String> amenities = ['Wifi', 'Điều hòa', 'Tủ lạnh', 'Máy giặt', 'Bếp', 'Bàn ghế', 'Gác lửng'];
  final List<String> furniture = ['Giường', 'Tủ quần áo', 'Bàn học', 'Ghế', 'Kệ sách'];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: provider.formKey2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tiện nghi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: amenities.map((item) => FilterChip(
                label: Text(item),
                selected: provider.selectedAmenities.contains(item),
                onSelected: (selected) {
                  if (selected) {
                    provider.selectedAmenities.add(item);
                  } else {
                    provider.selectedAmenities.remove(item);
                  }
                  provider.notifyListeners();
                },
                selectedColor: Colors.orange,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: provider.selectedAmenities.contains(item) ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              )).toList(),
            ),

            const SizedBox(height: 24),
            const Text('Nội thất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: furniture.map((item) => FilterChip(
                label: Text(item),
                selected: provider.selectedFurniture.contains(item),
                onSelected: (selected) {
                  if (selected) {
                    provider.selectedFurniture.add(item);
                  } else {
                    provider.selectedFurniture.remove(item);
                  }
                  provider.notifyListeners();
                },
                selectedColor: Colors.orange,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: provider.selectedAmenities.contains(item) ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[300]!),
                ),      
              )).toList(),
            ),

            const SizedBox(height: 24),
            _buildTextField(
              controller: provider.descriptionController,
              label: 'Mô tả chi tiết',
              hint: 'Nhập mô tả phòng (tối đa 500 ký tự)',
              icon: Icons.description,
              maxLines: 5,
              counter: '${provider.descriptionController.text.length}/500',
            ),
          ],
        ),
      ),
    );
  }
}

class Step3 extends StatelessWidget {
  final CreatePostProvider provider;
  const Step3({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh minh họa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm ít nhất 1 ảnh để bài đăng hấp dẫn hơn',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          InkWell(
            onTap: () => _pickImages(provider),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.orange.withAlpha(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.orange),
                  SizedBox(height: 8),
                  Text(
                    'Thêm ảnh',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (provider.selectedImages.isNotEmpty) ...[
            Text(
              'Ảnh đã chọn (${provider.selectedImages.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: provider.selectedImages.length,
              itemBuilder: (ctx, i) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(provider.selectedImages[i].path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () {
                          provider.selectedImages.removeAt(i);
                          provider.notifyListeners();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            const Center(
              child: Text(
                'Chưa có ảnh nào được chọn',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (provider.selectedImages.isEmpty)
            const Text(
              'Vui lòng thêm ít nhất 1 ảnh',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImages(CreatePostProvider provider) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      provider.selectedImages.addAll(picked);
      provider.notifyListeners();
    }
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  int maxLines = 1,
  String? counter,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.orange),
          suffixText: counter,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ],
  );
}

Widget _buildDropdown({
  required String label,
  required String value,
  required List<String> items,
  required IconData icon,
  required void Function(String?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );
}

Widget _buildRadio(String title, String value, CreatePostProvider provider) {
  return ListTile(
    title: Text(title, style: const TextStyle(fontSize: 14)),
    leading: Radio<String>(
      value: value,
      groupValue: provider.pricingType,
      onChanged: (v) {
        provider.pricingType = v!;
        provider.notifyListeners();
      },
    ),
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}