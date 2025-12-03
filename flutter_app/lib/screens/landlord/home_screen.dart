import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_rental_app/models/address.dart';
import 'package:room_rental_app/providers/room_provider.dart';
import 'package:room_rental_app/screens/landlord/create_hostel_screen.dart';
import 'package:room_rental_app/screens/landlord/my_hostels_screen.dart';
import 'package:room_rental_app/screens/room_detail_screen.dart';
import 'package:room_rental_app/ui/components/area_card.dart';
import 'package:room_rental_app/ui/components/room_post_card.dart';
import 'package:room_rental_app/ui/components/search_bar.dart';



class LandlordHomeScreen extends StatelessWidget {
  const LandlordHomeScreen({super.key});

  final List<Map<String, String>> managementCreation = const [
    {
      'name': 'Tạo toà nhà',
      'image':
          'https://images.unsplash.com/photo-1582407947304-fd86f028f716?w=800',
    },
    {
      'name': 'Tạo phòng',
      'image':
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
    },
    {
      'name': 'Tạo bài đăng',
      'image':
          'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
    },
    {
      'name': 'Tạo hợp đồng',
      'image':
          'https://images.unsplash.com/photo-1586287011575-4e2326b6a620?w=800',
    },
    {
      'name': 'Tạo hoá đơn',
      'image':
          'https://images.unsplash.com/photo-1588776814546-1ffcf47267a2?w=800',
    },
  ];

  final List<Map<String, String>> managementRent = const [
    {
      'name': 'Quản lý phòng',
      'image':
          'https://images.unsplash.com/photo-1593062096033-9a26b6c2f31e?w=800',
    },
    {
      'name': 'Quản lý bài đăng',
      'image':
          'https://images.unsplash.com/photo-1556767576-5ec41a9fafa3?w=800',
    },
    {
      'name': 'Quản lý khách thuê',
      'image':
          'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=800',
    },
    {
      'name': 'Quản lý hợp đồng',
      'image':
          'https://images.unsplash.com/photo-1586287011575-4e2326b6a620?w=800',
    },
    {
      'name': 'Quản lý hoá đơn',
      'image':
          'https://images.unsplash.com/photo-1588776814546-1ffcf47267a2?w=800',
    },
  ];

  final List<Map<String, String>> popularAreas = const [
    {
      'name': 'Trường Vinh',
      'image':
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800',
    },
    {
      'name': 'Thành Vinh',
      'image':
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
    },
    {
      'name': 'Vinh Hưng',
      'image':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
    },
    {
      'name': 'Vinh Phú',
      'image':
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
    },
    {
      'name': 'Vinh Lộc',
      'image':
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
    },
    {
      'name': 'Cửa Lò',
      'image':
          'https://images.unsplash.com/photo-1600565193348-f74bd3c7ccdf?w=800',
    },
  ];

  Map<String, dynamic> _convertMap(dynamic data) {
    if (data is! Map<String, dynamic>) return {};
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is List) {
        result[key] = value.map((e) {
          if (e is Timestamp) return e.toDate().toIso8601String();
          return e.toString();
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1000',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'RENTIFY ĐỒNG HÀNH CÙNG BẠN',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tặng ngay 50K',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Khi thuê phòng qua App RENTIFY',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CustomSearchBar(),
              ),

              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.explore, color: Colors.orange, size: 24),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: managementCreation.length,
                  itemBuilder: (ctx, i) {
                    final item = managementCreation[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          if (item['name'] == 'Tạo toà nhà') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateHostelScreen()),
                            );
                          }
                        },
                        child: AreaCard(
                          name: item['name']!,
                          imageUrl: item['image']!,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: managementRent.length,
                  itemBuilder: (ctx, i) {
                    final item = managementRent[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          if (item['name'] == 'Quản lý phòng') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyHostelsScreen()),
                            );
                          }
                        },
                        child: AreaCard(
                          name: item['name']!,
                          imageUrl: item['image']!,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Khám phá',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popularAreas.length,
                  itemBuilder: (ctx, i) => AreaCard(
                    name: popularAreas[i]['name']!,
                    imageUrl: popularAreas[i]['image']!,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.apartment,
                      color: Color.fromARGB(255, 134, 95, 36),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đối tác RENTIFY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Xem thêm',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Provider.of<RoomProvider>(
                  context,
                  listen: false,
                ).getAvailableRoomPosts(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Chưa có phòng trống nào'),
                      ),
                    );
                  }

                  var posts = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: posts.length,
                    itemBuilder: (ctx, i) {
                      var post = posts[i];
                      var room = post['room'];
                      var address = post['address'] as Address?;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailScreen(
                                room: _convertMap({
                                  'id': room.id,
                                  'ownerId': room.ownerId,
                                  'title': room.title,
                                  'roomNumber': room.roomNumber,
                                  'price': room.price,
                                  'description': room.description,
                                  'images': room.images,
                                  'floor': room.floor,
                                  'area': room.area,
                                  'capacity': room.capacity,
                                  'createdAt': room.createdAt,
                                  'updatedAt': room.updatedAt,
                                  'amenities': room.amenities,
                                  'furniture': room.furniture,
                                }),
                                roomId: room.id,
                              ),
                            ),
                          );
                        },
                        child: RoomPostCard(
                          title: '${room.title} - Phòng ${room.roomNumber}',
                          price:
                              '${room.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ/tháng',
                          address:
                              '${address?.street ?? ''}${address?.street != null ? ', ' : ''}${address?.ward ?? ''}',
                          district: address?.city ?? 'Vinh',
                          availableRooms: 1,
                          imageUrl: room.images?.isNotEmpty == true
                              ? room.images!.first
                              : 'https://via.placeholder.com/150',
                          isTrusted: true,
                          ownerName: 'Đối tác',
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
