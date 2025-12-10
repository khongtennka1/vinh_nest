import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_rental_app/models/contract.dart';
import 'package:url_launcher/url_launcher.dart';

class ContractDetailScreen extends StatelessWidget {
  final Contract contract;
  const ContractDetailScreen({required this.contract, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hợp đồng'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Thông tin người thuê'),
            _infoRow('Họ tên', contract.tenantName),
            _infoRow('SĐT', contract.tenantPhone),
            if (contract.tenantEmail.isNotEmpty) _infoRow('Email', contract.tenantEmail),
            _infoRow('CMND/CCCD', contract.tenantIdNumber),

            const SizedBox(height: 16),
            if (contract.tenantIdImages.isNotEmpty) ...[
              const Text('Ảnh CMND/CCCD', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: contract.tenantIdImages.map((url) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => launchUrl(Uri.parse(url)),
                      child: Image.network(url, height: 150, fit: BoxFit.cover),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            _sectionTitle('Thời hạn & tiền thuê'),
            _infoRow('Từ ngày', DateFormat('dd/MM/yyyy').format(contract.startDate)),
            _infoRow('Đến ngày', DateFormat('dd/MM/yyyy').format(contract.endDate)),
            _infoRow('Tiền phòng', '${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(contract.monthlyRent)}/tháng'),
            _infoRow('Ngày tính tiền', DateFormat('dd/MM/yyyy').format(contract.rentStartCalcDate)),
            _infoRow('Kì thanh toán', contract.paymentCycle),

            if (contract.services.isNotEmpty) ...[
              _sectionTitle('Phí dịch vụ'),
              ...contract.services.map((s) => _infoRow(s['name'], NumberFormat.currency(locale: 'vi', symbol: 'đ').format(s['price']))),
            ],

            if (contract.interiorItems.isNotEmpty) ...[
              _sectionTitle('Nội thất bàn giao'),
              Wrap(
                spacing: 8,
                children: contract.interiorItems.map((item) => Chip(label: Text(item))).toList(),
              ),
            ],

            if (contract.contractImages.isNotEmpty) ...[
              _sectionTitle('Ảnh phòng & hợp đồng'),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: contract.contractImages.map((url) => GestureDetector(
                  onTap: () => launchUrl(Uri.parse(url)),
                  child: Image.network(url, fit: BoxFit.cover),
                )).toList(),
              ),
            ],

            if (contract.note.isNotEmpty) ...[
              _sectionTitle('Ghi chú'),
              Text(contract.note),
            ],

            const SizedBox(height: 24),
            Center(
              child: Text(
                'Hợp đồng tạo ngày ${DateFormat('dd/MM/yyyy HH:mm').format(contract.createdAt)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
      );

  Widget _infoRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500))),
            Expanded(child: Text(value.toString())),
          ],
        ),
      );
}