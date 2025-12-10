import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:room_rental_app/providers/create_contract_provider.dart';
import 'package:room_rental_app/models/hostel.dart';
import 'package:room_rental_app/models/room.dart';
import 'package:room_rental_app/widgets/common_widgets.dart';

class CreateContractScreen extends StatelessWidget {
  const CreateContractScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateContractProvider()..loadMyHostels(),
      child: const _Step1Screen(),
    );
  }
}

class _Step1Screen extends StatelessWidget {
  const _Step1Screen();

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<CreateContractProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tạo hợp đồng thuê phòng'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: p.formKey1,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonWidgets.sectionTitle('Chọn toà nhà'),
              CommonWidgets.selectorCard(
                icon: Icons.apartment,
                title: p.selectedHostel?.name ?? 'Chưa chọn toà nhà',
                subtitle: p.selectedHostel != null ? 'Đã chọn' : 'Bắt buộc',
                onTap: () => _selectHostel(context),
              ),

              const SizedBox(height: 20),
              CommonWidgets.sectionTitle('Chọn phòng trống'),
              CommonWidgets.selectorCard(
                icon: Icons.door_front_door,
                title: p.selectedRoom != null ? 'Phòng ${p.selectedRoom!.roomNumber}' : 'Chưa chọn phòng',
                subtitle: p.selectedRoom != null
                    ? '${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(p.selectedRoom!.price)}/tháng'
                    : 'Bắt buộc',
                disabled: p.selectedHostel == null,
                onTap: p.selectedHostel == null ? null : () => _selectRoom(context),
              ),

              const SizedBox(height: 32),
              CommonWidgets.sectionTitle('Thời hạn hợp đồng'),
              Row(
                children: [
                  Expanded(child: CommonWidgets.datePicker(context: context, label: 'Từ ngày *', date: p.startDate, onPicked: (d) => p.startDate = d)),
                  const SizedBox(width: 12),
                  Expanded(child: CommonWidgets.datePicker(context: context, label: 'Đến ngày *', date: p.endDate, onPicked: (d) => p.endDate = d)),
                ],
              ),
              const SizedBox(height: 16),
              CommonWidgets.datePicker(context: context, label: 'Ngày bắt đầu tính tiền *', date: p.rentStartCalcDate, onPicked: (d) => p.rentStartCalcDate = d),

              const SizedBox(height: 24),
              CommonWidgets.moneyField(label: 'Tiền phòng/tháng *', controller: p.monthlyRentController),
              const SizedBox(height: 12),
              CommonWidgets.moneyField(label: 'Tiền đặt cọc', controller: p.depositController),

              const SizedBox(height: 24),
              CommonWidgets.sectionTitle('Chu kỳ thanh toán'),
              DropdownButtonFormField<String>(
                value: p.paymentCycle,
                decoration: const InputDecoration(filled: true, fillColor: Colors.white, prefixIcon: Icon(Icons.payment, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                items: p.paymentCycles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => p.paymentCycle = v!,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () {
            if (p.formKey1.currentState!.validate()) {
              final providerInstance = Provider.of<CreateContractProvider>(context, listen: false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (routeCtx) => ChangeNotifierProvider.value(
                    value: providerInstance,
                    child: const _Step2Screen(),
                  ),
                ),
              );
            }
          },
          child: const Text('Tiếp theo → Thông tin người thuê', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}

class _Step2Screen extends StatelessWidget {
  const _Step2Screen();

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<CreateContractProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Thông tin người thuê'), backgroundColor: Colors.orange, foregroundColor: Colors.white, centerTitle: true),
      body: Form(
        key: p.formKey2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonWidgets.sectionTitle('Thông tin người thuê chính'),
              CommonWidgets.inputField(label: 'Họ và tên *', controller: p.tenantNameController, icon: Icons.person, requiredField: true),
              CommonWidgets.inputField(label: 'Số điện thoại *', controller: p.tenantPhoneController, icon: Icons.phone, requiredField: true),
              CommonWidgets.inputField(label: 'Email', controller: p.tenantEmailController, icon: Icons.email),
              CommonWidgets.inputField(label: 'CMND/CCCD *', controller: p.tenantIdNumberController, icon: Icons.credit_card, requiredField: true),

              const SizedBox(height: 24),
              const Text('Ảnh CMND/CCCD (mặt trước + mặt sau) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              CommonWidgets.imageGrid(images: p.tenantIdImages, onAdd: () => _pickImages(p.tenantIdImages, 2, context), maxImages: 2),

              const SizedBox(height: 32),
              Row(
                children: [
                  const Text('Thành viên ở chung (nếu có)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.orange, size: 36),
                    onPressed: () => _showAddMemberDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              p.additionalMembers.isEmpty
                  ? const Text('Chưa có thành viên nào', style: TextStyle(color: Colors.grey))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.additionalMembers.map((name) => Chip(
                        label: Text(name),
                        backgroundColor: Colors.orange[50],
                        deleteIconColor: Colors.red,
                        onDeleted: () {
                          p.additionalMembers.remove(name);
                          p.updateMonthlyRent();
                          p.notifyListeners();
                        },
                      )).toList(),
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: p.tenantIdImages.length < 2 ? null : () {
            if (p.formKey2.currentState!.validate()) {
              final providerInstance = Provider.of<CreateContractProvider>(context, listen: false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (routeCtx) => ChangeNotifierProvider.value(
                    value: providerInstance,
                    child: const _Step3Screen(),
                  ),
                ),
              );
            }
          },
          child: const Text('Tiếp theo → Dịch vụ & Nội thất', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}

void _showAddMemberDialog(BuildContext context) {
  final controller = TextEditingController();
  final p = Provider.of<CreateContractProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [Icon(Icons.person_add, color: Colors.orange), SizedBox(width: 12), Text('Thêm thành viên')]),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Nhập họ và tên',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty && !p.additionalMembers.contains(name)) {
              p.additionalMembers.add(name);
              p.updateMonthlyRent();
              p.notifyListeners();
            }
            Navigator.pop(context);
          },
          child: const Text('Thêm', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

class _Step3Screen extends StatelessWidget {
  const _Step3Screen();

  static final List<String> interiorOptions = [
    'Giường', 'Tủ quần áo', 'Bàn ghế', 'Điều hoà',
    'Tủ lạnh', 'Máy giặt', 'Bếp', 'Nóng lạnh'
  ];

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<CreateContractProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Dịch vụ & Nội thất'), backgroundColor: Colors.orange, foregroundColor: Colors.white, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonWidgets.sectionTitle('Dịch vụ đi kèm'),
            Row(
              children: [
                Expanded(flex: 3, child: TextField(controller: p.serviceNameController, decoration: const InputDecoration(hintText: 'Tên dịch vụ', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: TextField(controller: p.servicePriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Giá/tháng', border: OutlineInputBorder()))),
                IconButton(onPressed: p.addService, icon: const Icon(Icons.add_circle, color: Colors.green, size: 36)),
              ],
            ),
            const SizedBox(height: 12),
            ...p.services.map((s) => Card(
              child: ListTile(
                title: Text(s['name']),
                trailing: Text(NumberFormat.currency(locale: 'vi', symbol: 'đ').format(s['price']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                onTap: () => p.removeService(p.services.indexOf(s)),
              ),
            )),

            const SizedBox(height: 32),
            CommonWidgets.sectionTitle('Nội thất bàn giao'),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: interiorOptions.map((item) => FilterChip(
                label: Text(item),
                selected: p.interiorItems.contains(item),
                selectedColor: Colors.orange[100],
                checkmarkColor: Colors.orange,
                onSelected: (v) {
                  if (v) p.interiorItems.add(item); else p.interiorItems.remove(item);
                  p.notifyListeners();
                },
              )).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () {
            final providerInstance = Provider.of<CreateContractProvider>(context, listen: false);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (routeCtx) => ChangeNotifierProvider.value(
                  value: providerInstance,
                  child: const _Step4Screen(),
                ),
              ),
            );
          },
          child: const Text('Tiếp theo → Hoàn tất', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}

class _Step4Screen extends StatelessWidget {
  const _Step4Screen();

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<CreateContractProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Hoàn tất hợp đồng'), backgroundColor: Colors.orange, foregroundColor: Colors.white, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonWidgets.sectionTitle('Ảnh minh hoạ & hợp đồng'),
            const Text('Tối đa 10 ảnh', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            CommonWidgets.imageGrid(images: p.contractImages, onAdd: () => _pickImages(p.contractImages, 10, context), maxImages: 10),

            const SizedBox(height: 32),
            CommonWidgets.sectionTitle('Ghi chú thêm'),
            TextField(
              controller: p.noteController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Ghi chú riêng cho hợp đồng này...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 200),
            CommonWidgets.bigRedButton(
              text: 'HOÀN TẤT HỢP ĐỒNG',
              loading: p.isLoading,
              onPressed: p.isLoading ? null : () async {
                final success = await p.createContract(context);
                if (success && context.mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pickImages(List<XFile> list, int max, BuildContext context) async {
  final picked = await ImagePicker().pickMultiImage();
  if (picked != null && picked.isNotEmpty) {
    list
      ..clear()
      ..addAll(picked.take(max));
    Provider.of<CreateContractProvider>(context, listen: false).notifyListeners();
  }
}

Future<void> _selectHostel(BuildContext context) async {
  final p = Provider.of<CreateContractProvider>(context, listen: false);
  final hostel = await showDialog<Hostel>(
    context: context,
    builder: (_) => _HostelDialog(hostels: p.myHostels, loading: p.loadingHostels),
  );
  if (hostel != null) {
    p.selectedHostel = hostel;
    p.selectedRoom = null;
    p.roomsInSelectedHostel.clear();
    await p.loadRoomsInHostel(hostel.id);
    p.notifyListeners();
  }
}

Future<void> _selectRoom(BuildContext context) async {
  final p = Provider.of<CreateContractProvider>(context, listen: false);
  final room = await showDialog<Room>(
    context: context,
    builder: (_) => _RoomDialog(rooms: p.roomsInSelectedHostel, loading: p.loadingRooms),
  );
  if (room != null) {
    p.selectedRoom = room;
    p.monthlyRentController.text = NumberFormat('#,##0').format(room.price.toInt());
    p.updateMonthlyRent();
    p.notifyListeners();
  }
}

class _HostelDialog extends StatelessWidget {
  final List<Hostel> hostels;
  final bool loading;
  const _HostelDialog({required this.hostels, required this.loading});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn toà nhà'),
      content: loading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: hostels.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.home, color: Colors.orange),
                  title: Text(hostels[i].name),
                  subtitle: Text(hostels[i].addressId ?? 'Chưa có địa chỉ'),
                  onTap: () => Navigator.pop(context, hostels[i]),
                ),
              ),
            ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ'))],
    );
  }
}

class _RoomDialog extends StatelessWidget {
  final List<Room> rooms;
  final bool loading;
  const _RoomDialog({required this.rooms, required this.loading});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn phòng trống'),
      content: loading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: rooms.length,
                itemBuilder: (_, i) {
                  final r = rooms[i];
                  return ListTile(
                    title: Text('Phòng ${r.roomNumber}'),
                    subtitle: Text('${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(r.price)}/tháng'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.pop(context, r),
                  );
                },
              ),
            ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ'))],
    );
  }
}
