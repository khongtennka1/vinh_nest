import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:room_rental_app/models/hostel.dart';

class HostelDetailScreen extends StatelessWidget {
  final Hostel hostel;

  const HostelDetailScreen({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    final images = hostel.images;
    final facilities = hostel.facilities;
    final interiors = hostel.interiors;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.home_outlined, size: 100, color: Colors.white70),
                      ),
                    )
                  : CarouselSlider(
                      options: CarouselOptions(
                        height: 320,
                        viewportFraction: 1.0,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 4),
                        enlargeCenterPage: false,
                      ),
                      items: images.map((url) {
                        return Image.network(
                          url,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.share, color: Colors.white),
                ),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home_work, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hostel.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hostel.addressId,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.home, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '${hostel.roomTypes}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_parking, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '${hostel.numberParkingSpaces} chỗ để xe',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.orange),
                      ),
                    ],
                  ),

                  const Divider(height: 40, thickness: 1),

                  if (hostel.description != null && hostel.description!.isNotEmpty) ...[
                    _sectionTitle('Giới thiệu toà nhà'),
                    const SizedBox(height: 8),
                    Text(
                      hostel.description!,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (facilities.isNotEmpty) ...[
                    _sectionTitle('Tiện ích toà nhà'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: facilities.map((item) => Chip(
                        label: Text(item),
                        backgroundColor: Colors.blue.withAlpha(25),
                        labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                        avatar: const Icon(Icons.check, size: 16, color: Colors.blue),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (interiors.isNotEmpty) ...[
                    _sectionTitle('Nội thất tiêu chuẩn'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: interiors.map((item) => Chip(
                        label: Text(item),
                        backgroundColor: Colors.green.withAlpha(25),
                        labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        avatar: const Icon(Icons.check, size: 16, color: Colors.green),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (hostel.customServices.isNotEmpty) ...[
                    _sectionTitle('Dịch vụ đi kèm'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: hostel.customServices.map((service) => Chip(
                        label: Text('${service['name']}: ${service['price']}'),
                        backgroundColor: Colors.purple.withAlpha(25),
                        labelStyle: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w600),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đang mở form thêm phòng cho: ${hostel.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_home, size: 28),
                      label: const Text(
                        'Thêm phòng vào toà này',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.orange),
                label: const Text('Chỉnh sửa', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.door_front_door),
                label: const Text('Xem danh sách phòng', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Danh sách phòng – Sắp có!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}