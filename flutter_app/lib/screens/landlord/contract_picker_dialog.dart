import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:room_rental_app/models/contract.dart';

class ContractPickerDialog extends StatelessWidget {
  const ContractPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const AlertDialog(content: Text('Vui lòng đăng nhập lại!'));
    }

    return AlertDialog(
      title: const Text('Chọn hợp đồng đang hoạt động'),
      content: SizedBox(
        width: double.maxFinite,
        height: 520,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('contracts')
              .where('landlordId', isEqualTo: uid)
              .where('status', isEqualTo: 'active')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Không có hợp đồng đang hoạt động'));
            }

            final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final contract = Contract.fromMap(doc.data() as Map<String, dynamic>, doc.id);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade700,
                      child: Text(
                        contract.tenantName.isNotEmpty ? contract.tenantName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(contract.tenantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phòng ID: ${contract.roomId}'),
                        Text('Nhà trọ ID: ${contract.hostelId}'),
                        Text('Tiền thuê: ${currency.format(contract.monthlyRent)}'),
                        Text('Chu kỳ: ${contract.paymentCycle}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.pop(context, contract),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy'))],
    );
  }
}