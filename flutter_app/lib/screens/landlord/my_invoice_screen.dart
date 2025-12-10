import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:room_rental_app/models/invoice.dart';
import 'package:room_rental_app/screens/landlord/invoice_detail_screen.dart';

class MyInvoicesScreen extends StatefulWidget {
  const MyInvoicesScreen({super.key});
  @override
  State<MyInvoicesScreen> createState() => _MyInvoicesScreenState();
}

class _MyInvoicesScreenState extends State<MyInvoicesScreen> {
  String filter = 'all'; 

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final currency = NumberFormat.currency(locale: 'vi', symbol: 'đ');
    final monthFmt = DateFormat('MM/yyyy');
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hóa đơn'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => filter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('Tất cả')),
              PopupMenuItem(value: 'pending', child: Text('Chưa thu')),
              PopupMenuItem(value: 'paid', child: Text('Đã thu')),
              PopupMenuItem(value: 'overdue', child: Text('Quá hạn')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invoices')
            .where('landlordId', isEqualTo: uid)
            .orderBy('dueMonth', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final invoice = Invoice.fromMap(data, doc.id);
            final bool isOverdue = invoice.dueDate.isBefore(now) && invoice.status != 'paid';

            return switch (filter) {
              'pending' => invoice.status == 'pending' && !isOverdue,
              'paid' => invoice.status == 'paid',
              'overdue' => isOverdue,
              _ => true,
            };
          }).toList();

          if (docs.isEmpty) {
            String message = 'Chưa có hóa đơn nào';
            if (filter == 'pending') message = 'Không có hóa đơn chưa thu';
            if (filter == 'paid') message = 'Không có hóa đơn đã thu';
            if (filter == 'overdue') message = 'Không có hóa đơn quá hạn';

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final invoice = Invoice.fromMap(data, docs[i].id);
              final bool isOverdue = invoice.dueDate.isBefore(now) && invoice.status != 'paid';

              return Card(
                color: isOverdue ? Colors.red.shade50 : null,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: invoice.status == 'paid'
                        ? Colors.green
                        : isOverdue
                            ? Colors.red
                            : Colors.orange,
                    child: Text(
                      invoice.roomId.isNotEmpty ? invoice.roomId[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(invoice.tenantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phòng ${invoice.roomId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Tháng ${monthFmt.format(invoice.dueMonth)} • Hạn: ${DateFormat('dd/MM/yyyy').format(invoice.dueDate)}',
                          style: TextStyle(color: isOverdue ? Colors.red : Colors.grey[700])),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(invoice.totalAmount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: invoice.status == 'paid'
                              ? Colors.green
                              : isOverdue
                                  ? Colors.red
                                  : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          invoice.status == 'paid'
                              ? 'ĐÃ THU'
                              : isOverdue
                                  ? 'QUÁ HẠN'
                                  : 'CHƯA THU',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}