import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_rental_app/models/invoice.dart';
import 'package:room_rental_app/models/contract.dart';
import 'package:room_rental_app/screens/landlord/contract_picker_dialog.dart';
import 'package:room_rental_app/models/room.dart';

class MeterReading {
  final String type;
  final double newReading;
  double amount = 0;
  MeterReading(this.type, this.newReading);
}

class CreateInvoiceProvider with ChangeNotifier {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime dueDate = DateTime.now().add(const Duration(days: 7));

  Contract? selectedContract;
  Room? selectedRoom;

  final List<MeterReading> meterReadings = [];
  final List<ExtraFee> extraFees = [];
  final TextEditingController noteController = TextEditingController();

  List<Map<String, dynamic>> fixedServices = [];

  bool isLoading = false;

  double get totalAmount {
    if (selectedContract == null || selectedRoom == null) return 0;

    final int numberOfResidents = selectedContract!.additionalMembers.length + 1;

    double roomRent = selectedContract!.monthlyRent;

    if (selectedRoom != null && selectedRoom!.pricingType == 'per_person') {
      roomRent = selectedContract!.monthlyRent * numberOfResidents;
    }

    double total = roomRent;

    for (var m in meterReadings) total += m.amount;

    for (var service in fixedServices) {
      final name = (service['name'] as String).toLowerCase();
      if (!name.contains('dien') && !name.contains('dien') && !name.contains('nuoc') && !name.contains('nuoc')) {
        total += (service['price'] as num).toDouble();
      }
    }

    for (var e in extraFees) total += e.price;

    return total;
  }

  Future<void> pickContract(BuildContext context) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại')),
      );
      return;
    }

    final contract = await showDialog<Contract>(
      context: context,
      builder: (_) => const ContractPickerDialog(),
    );

    if (contract != null) {
      selectedContract = contract;

      try {
        final roomDoc = await FirebaseFirestore.instance
            .collection('hostels')
            .doc(contract.hostelId)
            .collection('rooms')
            .doc(contract.roomId)
            .get();

        if (roomDoc.exists) {
          selectedRoom = Room.fromMap(roomDoc.data()!, roomDoc.id);
        }
      } catch (e) {
        debugPrint('Lỗi lấy Room: $e');
        selectedRoom = null;
      }

      await _loadAllFixedServices(contract.hostelId);
      notifyListeners();
    }
  }

  Future<void> _loadAllFixedServices(String hostelId) async {
    if (hostelId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('hostels')
          .doc(hostelId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      fixedServices = List<Map<String, dynamic>>.from(data['customServices'] ?? []);

      for (var m in meterReadings) {
        final service = fixedServices.firstWhere(
          (s) => (s['name'] as String).toLowerCase().contains(m.type == 'electric' ? 'dien' : 'nuoc'),
          orElse: () => {'price': 0},
        );
        final price = (service['price'] as num?)?.toDouble() ?? 0;
        m.amount = m.newReading * price;
      }

      debugPrint('Đã load ${fixedServices.length} dịch vụ cố định');
    } catch (e) {
      debugPrint('Lỗi load dịch vụ: $e');
    }
    notifyListeners();
  }

  void addMeterReading(String type, double newReading) {
    if (newReading <= 0) return;

    final service = fixedServices.firstWhere(
      (s) => (s['name'] as String).toLowerCase().contains(type == 'electric' ? 'dien' : 'nuoc'),
      orElse: () => {'price': 0},
    );
    final price = (service['price'] as num?)?.toDouble() ?? 0;
    final amount = newReading * price;

    meterReadings.add(MeterReading(type, newReading)..amount = amount);
    notifyListeners();
  }

  void removeMeterReading(int index) {
    meterReadings.removeAt(index);
    notifyListeners();
  }

  void addExtra(String description, double price) {
    if (description.isNotEmpty && price > 0) {
      extraFees.add(ExtraFee(description: description, price: price));
      notifyListeners();
    }
  }

  void removeExtra(int index) {
    extraFees.removeAt(index);
    notifyListeners();
  }

  Future<bool> createInvoiceAndSchedule(BuildContext context) async {
    if (selectedContract == null || selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa chọn hợp đồng')));
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final invoiceRef = FirebaseFirestore.instance.collection('invoices').doc();

      final allServices = <ServiceItem>[];

      for (var s in fixedServices) {
        final name = s['name'] as String;
        final price = (s['price'] as num).toDouble();
        if (!name.toLowerCase().contains('dien') && !name.toLowerCase().contains('nuoc')) {
          allServices.add(ServiceItem(name: s['name'], price: (s['price'] as num).toDouble()));
        }
      }

      for (var m in meterReadings) {
        final name = m.type == 'electric' ? 'dien' : 'nuoc';
        final unit = m.type == 'electric' ? 'kWh' : 'm³';
        allServices.add(ServiceItem(name: '$name (${m.newReading} $unit)', price: m.amount));
      }

      final int totalPeople = selectedContract!.additionalMembers.length + 1;
      final double finalRoomRent = selectedRoom!.pricingType == 'per_person'
        ? selectedContract!.monthlyRent * totalPeople
        : selectedContract!.monthlyRent;

      final invoice = Invoice(
        id: invoiceRef.id,
        contractId: selectedContract!.id,
        tenantName: selectedContract!.tenantName,
        roomId: selectedContract!.roomNumber ?? selectedContract!.roomId,
        hostelId: selectedContract!.hostelId,
        landlordId: selectedContract!.landlordId,
        dueMonth: selectedMonth,
        dueDate: dueDate,
        roomRent: finalRoomRent,
        services: allServices,
        extraFees: extraFees,
        note: noteController.text,
        createdAt: DateTime.now(),
      );

      await invoiceRef.set(invoice.toMap());

      selectedContract = null;
      meterReadings.clear();
      extraFees.clear();
      noteController.clear();
      fixedServices.clear();

      isLoading = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo hóa đơn thành công!'), backgroundColor: Colors.green),
      );
      return true;
    } catch (e) {
      debugPrint('Lỗi tạo hóa đơn: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }
}