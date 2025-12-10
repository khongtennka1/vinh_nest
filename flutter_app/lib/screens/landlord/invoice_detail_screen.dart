import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_rental_app/models/invoice.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  static final currency = NumberFormat.currency(locale: 'vi', symbol: 'đ');
  static final dateFmt = DateFormat('dd/MM/yyyy');
  static final monthFmt = DateFormat('MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = invoice.dueDate.isBefore(DateTime.now()) && invoice.status != 'paid';

    return Scaffold(
      appBar: AppBar(
        title: Text('Hóa đơn ${monthFmt.format(invoice.dueMonth)}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: invoice.status == 'paid'
                  ? Colors.green.shade50
                  : isOverdue
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      invoice.status == 'paid'
                          ? Icons.check_circle
                          : isOverdue
                              ? Icons.warning_amber
                              : Icons.access_time,
                      size: 40,
                      color: invoice.status == 'paid'
                          ? Colors.green
                          : isOverdue
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.status == 'paid'
                              ? 'ĐÃ THANH TOÁN'
                              : isOverdue
                                  ? 'QUÁ HẠN'
                                  : 'CHƯA THANH TOÁN',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: invoice.status == 'paid'
                                ? Colors.green
                                : isOverdue
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ),
                        if (isOverdue)
                          Text(
                            'Quá hạn ${DateTime.now().difference(invoice.dueDate).inDays} ngày',
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            _buildInfoCard('Thông tin', [
              _infoRow('Khách thuê', invoice.tenantName),
              _infoRow('Phòng', invoice.roomId),
              _infoRow('Tháng thanh toán', monthFmt.format(invoice.dueMonth)),
              _infoRow('Hạn thanh toán', dateFmt.format(invoice.dueDate),
                  color: isOverdue ? Colors.red : null),
            ]),

            const SizedBox(height: 16),

            _buildInfoCard('Chi tiết tiền', [
              _moneyRow('Tiền phòng', invoice.roomRent),
              ...invoice.services.map((s) => _moneyRow('   • ${s.name}', s.price)),
              ...invoice.extraFees.map((e) => _moneyRow('   • ${e.description} (phát sinh)', e.price, isExtra: true)),
              const Divider(height: 32),
              _moneyRow('TỔNG CỘNG', invoice.totalAmount, isTotal: true),
            ]),

            if (invoice.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Ghi chú', [_infoRow('', invoice.note)]),
            ],

            const SizedBox(height: 40),

            if (invoice.status != 'paid')
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payments, size: 28),
                  label: const Text('ĐÁNH DẤU ĐÃ THU TIỀN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => _markAsPaid(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: TextStyle(color: color, fontSize: 15))),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double amount, {bool isTotal = false, bool isExtra = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 18 : 16,
                color: isExtra ? Colors.red : null,
              ),
            ),
          ),
          Text(
            currency.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 22 : 17,
              color: isExtra ? Colors.red : (isTotal ? Colors.red.shade700 : null),
            ),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Xác nhận đã thu tiền?'),
        content: Text('Hóa đơn tháng ${monthFmt.format(invoice.dueMonth)}\ncủa ${invoice.tenantName} sẽ được đánh dấu ĐÃ THANH TOÁN.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đã thu tiền'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoice.id)
          .update({'status': 'paid', 'paidAt': FieldValue.serverTimestamp()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu hóa đơn là ĐÃ THU'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }
}