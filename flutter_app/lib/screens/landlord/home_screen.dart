import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_rental_app/models/address.dart';
import 'package:room_rental_app/models/room.dart';
import 'package:room_rental_app/providers/room_provider.dart';
import 'package:room_rental_app/ai/chat_ai_screen.dart';
import 'package:room_rental_app/screens/landlord/create_contract_screen.dart';
import 'package:room_rental_app/screens/landlord/create_hostel_screen.dart';
import 'package:room_rental_app/screens/landlord/create_invoice_screen.dart';
import 'package:room_rental_app/screens/landlord/create_room_screen.dart';
import 'package:room_rental_app/screens/landlord/my_contracts_screen.dart';
import 'package:room_rental_app/screens/landlord/my_hostels_screen.dart';
import 'package:room_rental_app/screens/landlord/my_invoice_screen.dart';
import 'package:room_rental_app/screens/landlord/my_rooms_screen.dart';
import 'package:room_rental_app/screens/room_detail_screen.dart';
import 'package:room_rental_app/ui/components/area_card.dart';
import 'package:room_rental_app/ui/components/room_post_card.dart';
import 'package:room_rental_app/ui/components/search_bar.dart';

class LandlordHomeScreen extends StatelessWidget {
  const LandlordHomeScreen({super.key});

  final List<Map<String, String>> managementCreation = const [
  {
    'name': 'Tạo toà nhà',
    'image': 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800',
  },
  {
    'name': 'Tạo phòng',
    'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
  },
  {
    'name': 'Tạo bài đăng',
    'image': 'https://images.unsplash.com/photo-1494526585095-c41746248156?w=800',
  },
  {
    'name': 'Tạo hợp đồng',
    'image': 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=800',
  },
  {
    'name': 'Tạo hoá đơn',
    'image': 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
  },
];

final List<Map<String, String>> managementRent = const [
  {
    'name': 'Quản lý toà nhà',
    'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
  },
  {
    'name': 'Quản lý phòng',
    'image': 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800',
  },
  {
    'name': 'Quản lý bài đăng',
    'image': 'https://images.unsplash.com/photo-1556745757-8d76bdb6984b?w=800',
  },
  {
    'name': 'Quản lý khách thuê',
    'image': 'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=800',
  },
  {
    'name': 'Quản lý hợp đồng',
    'image': 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800',
  },
  {
    'name': 'Quản lý hoá đơn',
    'image': 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=800',
  },
];
  final List<Map<String, String>> popularAreas = const [
    {
      'name': 'Trường Vinh',
      'image': 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800',  
    },
    {
      'name': 'Thành Vinh',
      'image': 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800', 
    },
    {
      'name': 'Vinh Hưng',
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800', 
    },
    {
      'name': 'Vinh Phú',
      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',  
    },
    {
      'name': 'Vinh Lộc',
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800', 
    },
    {
      'name': 'Cửa Lò',
      'image': 'https://images.unsplash.com/photo-1600565193348-f74bd3c7ccdf?w=800',  
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatAiScreen())),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.purple, Colors.deepPurple], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.purple.withAlpha(50), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=400'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.smart_toy, color: Colors.white, size: 28),
                                  const SizedBox(width: 8),
                                  const Text('Trợ lý AI thông minh', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                                    child: const Text('MỚI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('Hỏi gì cũng trả lời: giá phòng, viết tin nhắn, tóm tắt hợp đồng...', style: TextStyle(color: Colors.white, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.yellow, size: 20),
                                  const SizedBox(width: 6),
                                  const Text('Đang hoạt động', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 15),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tạo mới',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: managementCreation.length,
                itemBuilder: (ctx, i) {
                  final item = managementCreation[i];
                  return GestureDetector(
                    onTap: () {
                      if (item['name'] == 'Tạo toà nhà') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateHostelScreen()));
                      } else if (item['name'] == 'Tạo phòng') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen()));
                      } else if (item['name'] == 'Tạo hợp đồng') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateContractScreen()));
                      } else if (item['name'] == 'Tạo hoá đơn') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
                      }
                    },
                    child: AreaCard(
                      name: item['name']!,
                      imageUrl: item['image']!,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quản lý',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: managementRent.length,
                itemBuilder: (ctx, i) {
                  final item = managementRent[i];
                  return GestureDetector(
                    onTap: () {
                      if (item['name'] == 'Quản lý toà nhà') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyHostelsScreen()));
                      } else if (item['name'] == 'Quản lý phòng') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRoomsScreen()));
                      } else if (item['name'] == 'Quản lý hợp đồng') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyContractsScreen()));
                      } else if (item['name'] == 'Quản lý hoá đơn') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyInvoicesScreen()));
                      }
                    },
                    child: AreaCard(
                      name: item['name']!,
                      imageUrl: item['image']!,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Khám phá khu vực phổ biến',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: popularAreas.length,
                itemBuilder: (ctx, i) {
                  final item = popularAreas[i];
                  return AreaCard(
                    name: item['name']!,
                    imageUrl: item['image']!,
                  );
                },
              ),

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
                stream: Provider.of<RoomProvider>(context, listen: false).getAvailableRoomPosts(),
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
                        child: Text('Chưa có phòng trống nào', style: TextStyle(fontSize: 16)),
                      ),
                    );
                  }

                  final posts = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final room = post['room'] as Room;
                      final Address? address = post['address'];

                      final String displayAddress = address != null
                          ? '${address.street}${address.street.isNotEmpty ? ', ' : ''}${address.ward}'
                          : 'Địa chỉ đang cập nhật';

                      final String district = address?.city.isNotEmpty == true
                          ? address!.city
                          : 'TP. Vinh';

                      final String imageUrl = room.images.isNotEmpty
                          ? room.images.first
                          : 'https://via.placeholder.com/300x200';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailScreen(
                                room: _convertMap(room.toMap()),
                                roomId: room.id,
                              ),
                            ),
                          );
                        },
                        child: RoomPostCard(
                          title: '${room.title} - Phòng ${room.roomNumber}',
                          price: '${room.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ/tháng',
                          address: displayAddress,
                          district: district,
                          availableRooms: 1,
                          imageUrl: imageUrl,
                          isTrusted: true,
                          ownerName: 'Đối tác RENTIFY',
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
