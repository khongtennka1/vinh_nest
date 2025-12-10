import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_rental_app/providers/user_provider.dart';

class UpgradePlanScreen extends StatelessWidget {
  const UpgradePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentPlan = userProvider.currentUser?.plan ?? "free";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nâng cấp tài khoản"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlanCard(
              context,
              title: "Free",
              price: "0đ",
              limit: "Đăng tối đa 3 phòng",
              isCurrent: currentPlan == "free",
              planKey: "free",
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: "Standard",
              price: "99.000đ / tháng",
              limit: "Đăng tối đa 20 phòng",
              isCurrent: currentPlan == "standard",
              planKey: "standard",
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: "Business",
              price: "299.000đ / tháng",
              limit: "Không giới hạn phòng",
              isCurrent: currentPlan == "business",
              planKey: "business",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String limit,
    required String planKey,
    required bool isCurrent,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(price, style: const TextStyle(fontSize: 18, color: Colors.blue)),
            const SizedBox(height: 8),
            Text(limit),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isCurrent
                  ? null
                  : () async {
                      await Provider.of<UserProvider>(context, listen: false)
                          .updateUser(
                        name: Provider.of<UserProvider>(context, listen: false)
                            .currentUser!
                            .name,
                        phone: Provider.of<UserProvider>(context, listen: false)
                                .currentUser!
                                .phone ??
                            "",
                        plan: planKey,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Bạn đã nâng cấp lên $title!")),
                      );
                    },
              child: Text(isCurrent ? "Đang sử dụng" : "Nâng cấp ngay"),
            ),
          ],
        ),
      ),
    );
  }
}
