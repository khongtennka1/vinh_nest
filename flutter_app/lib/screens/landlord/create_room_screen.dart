import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_rental_app/models/hostel.dart';
import 'package:room_rental_app/providers/create_post_provider.dart';
import 'package:room_rental_app/screens/landlord/create_hostel_screen.dart';
import 'package:room_rental_app/screens/landlord/update_plan_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<CreateRoomScreen> {
  Hostel? selectedHostel;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const SizedBox();
    }

    return ChangeNotifierProvider(
      create: (_) => CreatePostProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thêm phòng trọ'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ),
        body: selectedHostel == null
            ? _buildHostelSelector(user.uid)
            : _buildAddRoomForm(selectedHostel!),
      ),
    );
  }

  Future<bool> checkRoomLimitBeforePost(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return false;

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final userPlan = userDoc['plan'] ?? 'free';

  int limit = 3; 
  if (userPlan == "standard") limit = 20;
  if (userPlan == "business") limit = 999999;

  int totalRooms = 0;

  final hostels = await FirebaseFirestore.instance
      .collection('hostels')
      .where('ownerId', isEqualTo: user.uid)
      .get();

  for (var h in hostels.docs) {
    final rooms = await FirebaseFirestore.instance
        .collection('hostels')
        .doc(h.id)
        .collection('rooms')
        .get();

    totalRooms += rooms.docs.length;
  }

  if (totalRooms >= limit) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bạn đã đạt giới hạn đăng $limit phòng của gói $userPlan.")),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpgradePlanScreen()),
    );

    return false;
  }

  return true;
}


  Widget _buildHostelSelector(String ownerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hostels')
          .where('ownerId', isEqualTo: ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Lỗi tải dữ liệu'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final hostels = snapshot.data!.docs
            .map((doc) => Hostel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        if (hostels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bạn chưa có toà nhà nào'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateHostelScreen())),
                  child: const Text('Tạo toà nhà mới'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn toà nhà để thêm phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: hostels.length,
                  itemBuilder: (context, i) {
                    final hostel = hostels[i];
                    return Card(
                      child: ListTile(
                        leading: hostel.images.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(hostel.images[0], width: 60, height: 60, fit: BoxFit.cover))
                            : const Icon(Icons.home, size: 40),
                        title: Text(hostel.name),
                        subtitle: Text(hostel.addressId),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          setState(() {
                            selectedHostel = hostel;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddRoomForm(Hostel hostel) {
    return Consumer<CreatePostProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: IndexedStack(
            index: provider.currentStep,
            children: [
              _Step1(provider: provider),
              _Step2(provider: provider),
              _Step3(provider: provider),
            ],
          ),
          bottomNavigationBar: _bottomBar(context, provider, hostel.id),
        );
      },
    );
  }

  Widget _bottomBar(BuildContext context, CreatePostProvider provider, String hostelId) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (provider.currentStep > 0)
            Expanded(child: OutlinedButton(onPressed: provider.previousStep, child: const Text('Quay lại'))),
          if (provider.currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: provider.isLoading
              ? null
              : () async {
                  bool valid = true;
                  if (provider.currentStep == 0) {
                    valid = provider.formKey1.currentState!.validate();
                  } else if (provider.currentStep == 1) {
                    valid = provider.formKey2.currentState!.validate();
                  } else if (provider.currentStep == 2) {
                    if (provider.selectedImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ảnh')),
                      );
                      valid = false;
                    }
                  }

                  if (!valid) return;

                  if (provider.currentStep < 2) {
                    provider.nextStep();
                  } else {
                    bool allow = await checkRoomLimitBeforePost(context);
                    if (!allow) return;
                    
                    final success = await provider.createRoomForHostel(hostelId, context);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thêm phòng thành công!')),
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                },
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(provider.currentStep == 2 ? 'Hoàn thành' : 'Tiếp theo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final CreatePostProvider provider;
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
                color: Colors.orange,
              ),
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.titleControler,
              label: 'Tiêu đề *',
              hint: 'Nhập tiêu đề',
              icon: Icons.title,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Loại phòng *',
              value: provider.roomType,
              items: ['Phòng đơn', 'Phòng đôi', 'Phòng ghép', 'Căn hộ'],
              icon: Icons.home,
              onChanged: (v) {
                provider.roomType = v!;
                provider.notifyListeners();
              },
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: provider.addressController,
              label: 'Địa chỉ *',
              hint: 'Nhập địa chỉ',
              icon: Icons.location_on,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
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
              controller: provider.roomNumberController,
              label: 'Số phòng *',
              hint: 'Nhập số phòng',
              icon: Icons.confirmation_number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập số phòng' : null,
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
                if (v == null || v.isEmpty) return 'Vui lòng nhập sức chứa';
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
                if (current > capacity)
                  return 'Không thể vượt quá sức chứa ($capacity người)';
                return null;
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Tiền phòng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),

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
                Expanded(
                  child: _buildRadio('Theo đầu người', 'per_person', provider),
                ),
                Expanded(
                  child: _buildRadio('Theo phòng', 'per_room', provider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  final CreatePostProvider provider;
  _Step2({required this.provider});

  final List<String> amenities = [
    'Wifi',
    'Điều hòa',
    'Tủ lạnh',
    'Máy giặt',
    'Bếp',
    'Bàn ghế',
    'Gác lửng',
  ];
  final List<String> furniture = [
    'Giường',
    'Tủ quần áo',
    'Bàn học',
    'Ghế',
    'Kệ sách',
  ];

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
              'Tiện nghi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: amenities
                  .map(
                    (item) => FilterChip(
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
                        color: provider.selectedAmenities.contains(item)
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),
            const Text(
              'Nội thất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: furniture
                  .map(
                    (item) => FilterChip(
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
                        color: provider.selectedAmenities.contains(item)
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  )
                  .toList(),
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
  final CreatePostProvider provider;
  const _Step3({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: provider.formKey3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ảnh minh họa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm ít nhất 1 ảnh để bài đăng hấp dẫn hơn',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () => _pickAndUploadImages(context),
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
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                      Text(
                        'Ảnh đã chọn (${provider.selectedImages.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                        itemCount: provider.selectedImages.length,
                        itemBuilder: (ctx, i) {
                          final local = provider.selectedImages[i];
                          final uploadedUrl = (i < provider.imageUrls.length)
                              ? provider.imageUrls[i]
                              : null;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(local.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              if (uploadedUrl == null)
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Chưa upload',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              if (uploadedUrl != null)
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Uploaded',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
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
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  )
                : const Center(
                    child: Text(
                      'Chưa có ảnh nào được chọn',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

            if (provider.selectedImages.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Vui lòng thêm ít nhất 1 ảnh',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImages(BuildContext context) async {
    final provider = context.read<CreatePostProvider>();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload ảnh thất bại, thử lại sau')),
        );
        return;
      }
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Upload ảnh thành công')));
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
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
