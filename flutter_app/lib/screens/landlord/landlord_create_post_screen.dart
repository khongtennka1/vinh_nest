import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/landlord/create_post_provider.dart';

class LandlordCreatePostScreen extends StatelessWidget {
  const LandlordCreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LandlordCreatePostProvider(),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatelessWidget {
  const _CreatePostView();

  @override
  Widget build(BuildContext context) {
    return Consumer<LandlordCreatePostProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            title: Text('Tạo bài đăng - Bước ${provider.currentStep + 1}/3'),
            centerTitle: true,
          ),
          body: _buildStep(context, provider),
          bottomNavigationBar: _buildBottomBar(context, provider),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, LandlordCreatePostProvider provider) {
    switch (provider.currentStep) {
      case 0:
        return _Step1(provider: provider);
      case 1:
        return _Step2(provider: provider);
      case 2:
        return _Step3(provider: provider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomBar(BuildContext context, LandlordCreatePostProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (provider.currentStep > 0)
            Expanded(
              child: OutlinedButton(onPressed: provider.previousStep, child: const Text('Quay lại')),
            ),
          if (provider.currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (provider.currentStep < 2) {
                        final isValid = provider.currentStep == 0
                            ? provider.formKey1.currentState!.validate()
                            : provider.formKey2.currentState!.validate();
                        if (isValid) provider.nextStep();
                      } else {
                        final success = await provider.createPost(context);
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
                padding: const EdgeInsets.symmetric(vertical: 16)),
              child: provider.isLoading 
              ? const CircularProgressIndicator(
                color: Colors.white) 
                : Text(provider.currentStep == 2 ? 'Đăng tin' : 'Tiếp theo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final LandlordCreatePostProvider provider;
  const _Step1({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: provider.formKey1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin phòng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange
              )
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.titleControler,
              label: 'Số/Tên phòng *',
              hint: 'Nhập số/tên phòng',
              icon: Icons.title,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập số / tên phòng' : null),

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

            _buildTextField(
              controller: provider.addressController,
              label: 'Địa chỉ *',
              hint: 'Nhập địa chỉ',
              icon: Icons.location_on,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Loại phòng *',
              value: provider.roomType,
              items: ['Phòng trọ', 'Chung cư mini', 'Nhà nguyên căn', 'Ký túc xá', 'Homestay', 'Chung cư','Khác'],
              icon: Icons.home,
              onChanged: (v) { provider.roomType = v!; provider.notifyListeners();
              }
            ),

            const SizedBox(height: 16),

            _buildTextField(controller: provider.floorController,
              label: 'Tầng *',
              hint: 'Nhập tầng',
              icon: Icons.stairs,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập tầng' : null
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.roomNumberController,
              label: 'Số phòng *',
              hint: 'Nhập số phòng',
              icon: Icons.confirmation_number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập số phòng' : null
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.areaController,
              label: 'Diện tích (m²) *',
              hint: 'Nhập diện tích',
              icon: Icons.square_foot,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập diện tích' : null
            ),
          ],
        ),
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  final LandlordCreatePostProvider provider;
  _Step2({required this.provider});

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
            const Text(
              'Tiền phòng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange
              )
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.priceController,
              label: 'Giá thuê (VND/tháng) *',
              hint: 'Nhập số tiền',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập giá' : null
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.depositController,
              label: 'Tiền đặt cọc (VND) *',
              hint: 'Nhập số tiền đặt cọc',
              icon: Icons.money_off,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập tiền đặt cọc' : null
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.promotionalOffersController,
              label: 'Ưu đãi khuyến mãi',
              hint: 'Nhập số tiền khuyến mãi',
              icon: Icons.local_offer,
              keyboardType: TextInputType.number,
              validator: (p0) => null,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.promotionalperiodStartController,
              label: 'Thời gian bắt đầu khuyến mãi',
              hint: 'Nhập thời gian bắt đầu',
              icon: Icons.date_range,
              keyboardType: TextInputType.datetime,
              validator: (p0) => null,
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: provider.promotionalperiodEndController,
              label: 'Thời gian kết thúc khuyến mãi',
              hint: 'Nhập thời gian kết thúc',
              icon: Icons.date_range,
              keyboardType: TextInputType.datetime,
              validator: (p0) => null,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildRadio(
                    'Theo đầu người',
                    'per_person',
                    provider
                  )
                ),
                Expanded(
                  child: _buildRadio(
                    'Theo phòng',
                    'per_room',
                    provider
                  )
                )
              ]
            ),

            const SizedBox(height: 16),

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

class _Step3 extends StatelessWidget {
  final LandlordCreatePostProvider provider;
  const _Step3({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: provider.formKey3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ảnh minh họa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          const Text('Thêm ít nhất 1 ảnh để bài đăng hấp dẫn hơn', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),

          InkWell(
            onTap: () => _pickAndUploadImages(context),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.orange,
                  width: 2
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.orange.withAlpha(10)
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.orange
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Thêm ảnh',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600
                    )
                  ) 
                ]
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (provider.isUploadingImages) const LinearProgressIndicator(),

          const SizedBox(height: 8),

          provider.selectedImages.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ảnh đã chọn (${provider.selectedImages.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1
                    ),
                    itemCount: provider.selectedImages.length,
                    itemBuilder: (ctx, i) {
                      final local = provider.selectedImages[i];
                      final uploadedUrl = (i < provider.imageUrls.length) ? provider.imageUrls[i] : null;
                      return Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(local.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity
                        )),
                        if (uploadedUrl == null)
                          Positioned(bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8)),
                                child: const Text(
                                  'Chưa upload',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12
                                  )
                                )
                              )
                          ),
                        if (uploadedUrl != null)
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Text(
                                'Uploaded',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12
                                )
                              )
                            )
                          ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: () {
                              provider.removeImageAt(i); 
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white
                              )
                            )
                          )
                        ),
                      ]);
                    },
                  ),
                ],
              )
            : const Center(child: Text('Chưa có ảnh nào được chọn', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),

          if (provider.selectedImages.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 16), child: Text('Vui lòng thêm ít nhất 1 ảnh', style: TextStyle(color: Colors.red, fontSize: 13))),
        ]),
      ),
    );
  }

  Future<void> _pickAndUploadImages(BuildContext context) async {
    final provider = context.read<LandlordCreatePostProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;

    provider.addLocalImages(picked);

    for (int i = 0; i < provider.selectedImages.length; i++) {
      if (i < provider.imageUrls.length) continue;
      provider.isUploadingImages = true;
      provider.notifyListeners();
      final ok = await provider.uploadImageFileAt(i);
      provider.isUploadingImages = false;
      provider.notifyListeners();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload ảnh thất bại, thử lại sau')));
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload ảnh thành công')));
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
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          icon, color: Colors.orange
        ),
        suffixText: counter,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12
        )
      )
    ),
  ]);
}

Widget _buildDropdown({required String label, required String value, required List<String> items, required IconData icon, required void Function(String?) onChanged}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon, color: Colors.orange
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)
        )
      )
    ),
  ]);
}

Widget _buildRadio(String title, String value, LandlordCreatePostProvider provider) {
  return ListTile(
    title: Text(
      title,
      style: const TextStyle(fontSize: 14)
    ),
    leading: Radio<String>(
      value: value,
      groupValue: provider.pricingType,
      onChanged: (v) {
        provider.pricingType = v!; provider.notifyListeners(); 
      }
    ),
    contentPadding: EdgeInsets.zero, dense: true
  );
}
