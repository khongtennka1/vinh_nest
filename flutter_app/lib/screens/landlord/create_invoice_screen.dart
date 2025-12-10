import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:room_rental_app/providers/create_invoice_provider.dart';

class CreateInvoiceScreen extends StatelessWidget {
  const CreateInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateInvoiceProvider(),
      child: const _CreateInvoiceBody(),
    );
  }
}

class _CreateInvoiceBody extends StatelessWidget {
  const _CreateInvoiceBody();

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<CreateInvoiceProvider>(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final monthFmt = DateFormat('MM/yyyy', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo hóa đơn tiền phòng'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.orange, size: 28),
                        SizedBox(width: 12),
                        Text('Thông tin hóa đơn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildMonthPicker(context, p, monthFmt),
                    const SizedBox(height: 20),

                    _buildDueDatePicker(context, p, dateFmt),
                    const SizedBox(height: 24),

                    _buildContractPicker(p, context),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.electric_meter, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        const Text('Điện & Nước', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.orange, size: 32),
                          onPressed: () => _showElectricWaterDialog(context, p),
                        ),
                      ],
                    ),
                    const Divider(),

                    p.meterReadings.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('Chưa nhập công tơ điện/nước\nBấm nút + để thêm', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: p.meterReadings.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final item = p.meterReadings[i];
                              final icon = item.type == 'electric' ? Icons.electrical_services : Icons.water_drop;
                              final color = item.type == 'electric' ? Colors.orange : Colors.blue;
                              final unit = item.type == 'electric' ? 'kWh' : 'm³';

                              return ListTile(
                                leading: CircleAvatar(backgroundColor: color.withAlpha(25), child: Icon(icon, color: color)),
                                title: Text(item.type == 'electric' ? 'Điện' : 'Nước', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('Số mới: ${item.newReading} $unit'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(currency.format(item.amount), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => p.removeMeterReading(i),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            _buildExtraSection(p, context, currency),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: p.noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ghi chú cho khách (không bắt buộc)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Card(
              color: const Color.fromARGB(255, 220, 80, 60),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TỔNG CỘNG PHẢI THU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(currency.format(p.totalAmount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: p.isLoading ? null : () async {
                  final success = await p.createInvoiceAndSchedule(context);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo hóa đơn thành công!'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  }
                },
                child: p.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('TẠO HÓA ĐƠN & GỬI NHẮC HẸN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPicker(BuildContext context, CreateInvoiceProvider p, DateFormat fmt) {
    return InkWell(
      onTap: () async {
        final picked = await showMonthPicker(
          context: context,
          initialDate: p.selectedMonth,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) p.selectedMonth = DateTime(picked.year, picked.month);
      },
      child: _infoRow(Icons.calendar_month, 'Tháng hóa đơn', fmt.format(p.selectedMonth)),
    );
  }

  Widget _buildDueDatePicker(BuildContext context, CreateInvoiceProvider p, DateFormat fmt) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: p.dueDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          locale: const Locale('vi', 'VN'),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.orange)),
            child: child!,
          ),
        );
        if (date != null) p.dueDate = date;
      },
      child: _infoRow(Icons.access_time, 'Hạn thanh toán', fmt.format(p.dueDate), color: Colors.red),
    );
  }

  Widget _buildContractPicker(CreateInvoiceProvider p, BuildContext context) {
    return InkWell(
      onTap: () {
        Future.microtask(() => p.pickContract(context));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.selectedContract == null ? Colors.red.shade50 : Colors.green.shade50,
          border: Border.all(color: p.selectedContract == null ? Colors.red : Colors.green, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(p.selectedContract == null ? Icons.warning_amber : Icons.check_circle,
                color: p.selectedContract == null ? Colors.red : Colors.green, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.selectedContract == null ? 'Chưa chọn hợp đồng' : 'Đã chọn hợp đồng',
                      style: TextStyle(color: p.selectedContract == null ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    p.selectedContract == null
                        ? 'Bắt buộc chọn hợp đồng đang hoạt động'
                        : '${p.selectedContract!.tenantName}\n'
                          'Phòng: ${p.selectedContract!.roomNumber ?? p.selectedContract!.roomId}\n'
                          'Số người: ${p.selectedContract!.additionalMembers.length + 1} người\n'
                          'Tiền phòng: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(p.totalAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: p.selectedContract == null ? Colors.red.shade700 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: (color ?? Colors.orange).withAlpha(77)),
        borderRadius: BorderRadius.circular(12),
        color: (color ?? Colors.orange).withAlpha(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.orange),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color ?? Colors.orange)),
        ],
      ),
    );
  }

  void _showElectricWaterDialog(BuildContext context, CreateInvoiceProvider p) {
    final electricCtrl = TextEditingController();
    final waterCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.electric_meter, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Nhập công tơ điện & nước', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: electricCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số điện mới (kWh)',
                prefixIcon: const Icon(Icons.electrical_services, color: Colors.orange),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.orange.shade50,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: waterCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số nước mới (m³)',
                prefixIcon: const Icon(Icons.water_drop, color: Colors.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.blue.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              final electric = double.tryParse(electricCtrl.text) ?? 0;
              final water = double.tryParse(waterCtrl.text) ?? 0;

              if (electric == 0 && water == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập ít nhất 1 trong 2 số')),
                );
                return;
              }

              if (electric > 0) p.addMeterReading('electric', electric);
              if (water > 0) p.addMeterReading('water', water);

              Navigator.pop(context);
            },
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraSection(CreateInvoiceProvider p, BuildContext context, NumberFormat currency) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                const Text('Phí phát sinh (nếu có)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.red),
                  onPressed: () => _showAddExtraDialog(context, p),
                ),
              ],
            ),
            const Divider(),
            p.extraFees.isEmpty
                ? const Padding(padding: EdgeInsets.all(20), child: Text('Không có phí phát sinh', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: p.extraFees.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = p.extraFees[i];
                      return ListTile(
                        title: Text(e.description),
                        trailing: Text(currency.format(e.price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        onTap: () => p.removeExtra(i),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showAddExtraDialog(BuildContext context, CreateInvoiceProvider p) {
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm phí phát sinh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
            const SizedBox(height: 12),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số tiền (VNĐ)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final price = double.tryParse(priceCtrl.text.replaceAll(RegExp(r'[.,đ]'), '')) ?? 0;
              if (price > 0 && descCtrl.text.trim().isNotEmpty) {
                p.addExtra(descCtrl.text.trim(), price);
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}