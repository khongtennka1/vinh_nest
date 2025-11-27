import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../models/hostel.dart';
import '../models/address.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui/components/search_bar.dart';
import '../ui/components/feature_button.dart';
import '../ui/components/area_card.dart';
import '../ui/components/room_post_card.dart';
import 'room/room_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, String>> popularAreas = const [
    {
      'name': 'Trường Vinh',
      'image':
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?q=80&w=800',
    },
    {
      'name': 'Thành Vinh',
      'image':
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?q=80&w=800',
    },
    {
      'name': 'Vinh Hưng',
      'image':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=800',
    },
    {
      'name': 'Vinh Phú',
      'image':
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?q=80&w=800',
    },
    {
      'name': 'Vinh Lộc',
      'image':
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800',
    },
    {
      'name': 'Cửa Lò',
      'image':
          'https://images.unsplash.com/photo-1600565193348-f74bd3c7ccdf?q=80&w=800',
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
                      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?q=80&w=1000',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'VINHNEST ĐỒNG HÀNH CÙNG BẠN',
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
                            'Khi thuê phòng qua App VinhNest',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CustomSearchBar(),
              ),

              SizedBox(height: 20),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FeatureButton(
                      icon: Icons.local_offer,
                      label: 'Săn phòng\ngiảm giá',
                      color: Colors.red,
                    ),
                    FeatureButton(
                      icon: Icons.near_me,
                      label: 'Tìm phòng\nquanh đây',
                      color: Colors.green,
                    ),
                    FeatureButton(
                      icon: Icons.people,
                      label: 'Tìm ở\nghép',
                      color: Colors.blue,
                    ),
                    FeatureButton(
                      icon: Icons.chair,
                      label: 'Nội thất\ngiá rẻ',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.explore, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Khám phá',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popularAreas.length,
                  itemBuilder: (ctx, i) => AreaCard(
                    name: popularAreas[i]['name']!,
                    imageUrl: popularAreas[i]['image']!,
                  ),
                ),
              ),

              SizedBox(height: 24),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.apartment,
                      color: const Color.fromARGB(255, 134, 95, 36),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đối tác VinhNest',
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

              SizedBox(height: 12),

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
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Chưa có phòng trống nào'),
                      ),
                    );
                  }

                  var posts = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: posts.length,
                    itemBuilder: (ctx, i) {
                      var post = posts[i];
                      var room = post['room'];
                      var hostel = post['hostel'] as Hostel;
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
