import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_rental_app/models/address.dart';
import 'package:room_rental_app/models/hostel.dart';
import 'package:room_rental_app/providers/room_provider.dart';
import 'package:room_rental_app/screens/room_detail_screen.dart';
import 'package:room_rental_app/ui/components/area_card.dart';
import 'package:room_rental_app/ui/components/feature_button.dart';
import 'package:room_rental_app/ui/components/room_post_card.dart';
import 'package:room_rental_app/ui/components/search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  // Filter state
  RangeValues _priceRange = const RangeValues(0, 3000000);
  RangeValues _areaRange = const RangeValues(0, 50);
  int _minCapacity = 0; // số người tối thiểu

  // Location dropdowns (mock data). In real app, load from Firestore or API.
  final Map<String, List<String>> _provinces = {
    'Nghệ An': ['Vinh', 'Cửa Lò', 'Diễn Châu'],
    'Hà Nội': ['Ba Đình', 'Hoàn Kiếm', 'Tây Hồ'],
  };
  final Map<String, List<String>> _districts = {
    'Vinh': ['Phường 1', 'Phường 2', 'Phường Bến Thủy'],
    'Cửa Lò': ['Thị xã 1', 'Thị xã 2'],
  };

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;

  // Amenities
  final List<String> _amenities = ['WiFi', 'Điều hoà', 'Nóng lạnh', 'Máy giặt'];
  final Set<String> _selectedAmenities = {};

  // Sort
  String _sortBy = 'Mặc định';

  // temporary values used inside modal before applying
  RangeValues _tempPriceRange = const RangeValues(0, 3000000);
  RangeValues _tempAreaRange = const RangeValues(0, 50);
  int _tempMinCapacity = 0;
  String? _tempSelectedProvince;
  String? _tempSelectedDistrict;
  String? _tempSelectedWard;
  Set<String> _tempSelectedAmenities = {};
  String _tempSortBy = 'Mặc định';

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

  void _openFilterSheet(BuildContext context) {
    // copy current values to temp
    _tempPriceRange = _priceRange;
    _tempAreaRange = _areaRange;
    _tempMinCapacity = _minCapacity;
    _tempSelectedProvince = _selectedProvince;
    _tempSelectedDistrict = _selectedDistrict;
    _tempSelectedWard = _selectedWard;
    _tempSelectedAmenities = Set.from(_selectedAmenities);
    _tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // helper to update dependent dropdowns
            void _onProvinceChanged(String? p) {
              setModalState(() {
                _tempSelectedProvince = p;
                _tempSelectedDistrict = null;
                _tempSelectedWard = null;
              });
            }

            void _onDistrictChanged(String? d) {
              setModalState(() {
                _tempSelectedDistrict = d;
                _tempSelectedWard = null;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Bộ lọc nâng cao',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price range
                            Text(
                              'Khoảng giá (đ/tháng)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            RangeSlider(
                              values: _tempPriceRange,
                              min: 0,
                              max: 5000000,
                              divisions: 50,
                              labels: RangeLabels(
                                _tempPriceRange.start.toInt().toString(),
                                _tempPriceRange.end.toInt().toString(),
                              ),
                              onChanged: (v) =>
                                  setModalState(() => _tempPriceRange = v),
                            ),
                            SizedBox(height: 12),

                            // Area range
                            Text(
                              'Diện tích (m²)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            RangeSlider(
                              values: _tempAreaRange,
                              min: 0,
                              max: 200,
                              divisions: 40,
                              labels: RangeLabels(
                                _tempAreaRange.start.toInt().toString(),
                                _tempAreaRange.end.toInt().toString(),
                              ),
                              onChanged: (v) =>
                                  setModalState(() => _tempAreaRange = v),
                            ),
                            SizedBox(height: 12),

                            // Capacity / số người
                            Row(
                              children: [
                                Text(
                                  'Số người tối thiểu:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 12),
                                DropdownButton<int>(
                                  value: _tempMinCapacity,
                                  items: List.generate(6, (i) => i).map((v) {
                                    return DropdownMenuItem(
                                      value: v,
                                      child: Text(
                                        v == 0 ? 'Không chọn' : v.toString(),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setModalState(
                                    () => _tempMinCapacity = v ?? 0,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            // Location dropdowns
                            Text(
                              'Tỉnh / Thành',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isDense: true,
                                    value: _tempSelectedProvince,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    items: _provinces.keys
                                        .map(
                                          (p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _onProvinceChanged,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isDense: true,
                                    value: _tempSelectedDistrict,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    items:
                                        (_tempSelectedProvince != null
                                                ? _provinces[_tempSelectedProvince!] ??
                                                      []
                                                : [])
                                            .map<DropdownMenuItem<String>>(
                                              (d) => DropdownMenuItem<String>(
                                                value: d,
                                                child: Text(d),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: _onDistrictChanged,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              value: _tempSelectedWard,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items:
                                  (_tempSelectedDistrict != null
                                          ? _districts[_tempSelectedDistrict!] ??
                                                []
                                          : [])
                                      .map<DropdownMenuItem<String>>(
                                        (w) => DropdownMenuItem<String>(
                                          value: w,
                                          child: Text(w),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) =>
                                  setModalState(() => _tempSelectedWard = v),
                            ),

                            SizedBox(height: 16),

                            // Amenities
                            Text(
                              'Tiện ích',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _amenities.map((a) {
                                final selected = _tempSelectedAmenities
                                    .contains(a);
                                return FilterChip(
                                  label: Text(a),
                                  selected: selected,
                                  onSelected: (v) {
                                    setModalState(() {
                                      if (v)
                                        _tempSelectedAmenities.add(a);
                                      else
                                        _tempSelectedAmenities.remove(a);
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 16),

                            // Sort
                            Text(
                              'Sắp xếp',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _tempSortBy,
                              items:
                                  [
                                        'Mặc định',
                                        'Giá: Thấp → Cao',
                                        'Giá: Cao → Thấp',
                                        'Diện tích: Lớn → Nhỏ',
                                      ]
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setModalState(
                                () => _tempSortBy = v ?? 'Mặc định',
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),

                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // reset
                            setModalState(() {
                              _tempPriceRange = const RangeValues(0, 3000000);
                              _tempAreaRange = const RangeValues(0, 50);
                              _tempMinCapacity = 0;
                              _tempSelectedProvince = null;
                              _tempSelectedDistrict = null;
                              _tempSelectedWard = null;
                              _tempSelectedAmenities.clear();
                              _tempSortBy = 'Mặc định';
                            });
                          },
                          child: Text(
                            'Đặt lại',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // apply filters to main state
                            setState(() {
                              _priceRange = _tempPriceRange;
                              _areaRange = _tempAreaRange;
                              _minCapacity = _tempMinCapacity;
                              _selectedProvince = _tempSelectedProvince;
                              _selectedDistrict = _tempSelectedDistrict;
                              _selectedWard = _tempSelectedWard;
                              _selectedAmenities.clear();
                              _selectedAmenities.addAll(_tempSelectedAmenities);
                              _sortBy = _tempSortBy;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Áp dụng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _postMatchesFilters(dynamic room, Map<String, dynamic>? addr) {
    // room is expected to be a data model with fields price, area, capacity, amenities
    double price = 0;
    double area = 0;
    int capacity = 0;

    try {
      final p = room.price;
      if (p is int) price = p.toDouble();
      if (p is double) price = p;
    } catch (_) {}

    try {
      final a = room.area;
      if (a is int) area = a.toDouble();
      if (a is double) area = a;
    } catch (_) {}

    try {
      final c = room.capacity;
      if (c is int) capacity = c;
      if (c is double) capacity = c.toInt();
    } catch (_) {}

    if (price < _priceRange.start || price > _priceRange.end) return false;
    if (area < _areaRange.start || area > _areaRange.end) return false;
    if (_minCapacity > 0 && capacity < _minCapacity) return false;

    // location filter (address may be null)
    if (_selectedProvince != null) {
      if (addr == null) return false;
      final city = addr['city'] ?? addr['province'] ?? '';
      if (city != _selectedProvince) return false;
      if (_selectedDistrict != null) {
        final district = addr['district'] ?? addr['city'] ?? '';
        if (district != _selectedDistrict) return false;
      }
      if (_selectedWard != null) {
        final ward = addr['ward'] ?? '';
        if (ward != _selectedWard) return false;
      }
    }

    // amenities
    if (_selectedAmenities.isNotEmpty) {
      try {
        final roomAmenities = List<String>.from(room.amenities ?? []);
        if (!_selectedAmenities.every((a) => roomAmenities.contains(a)))
          return false;
      } catch (_) {
        return false;
      }
    }

    return true;
  }

  List filteredAndSorted(List<Map<String, dynamic>> posts) {
    // Apply filters
    var list = posts.where((post) {
      var room = post['room'];
      var address = post['address'];
      return _postMatchesFilters(room, address);
    }).toList();

    // sort
    if (_sortBy == 'Giá: Thấp → Cao') {
      list.sort(
        (a, b) => (a['room'].price ?? 0).compareTo(b['room'].price ?? 0),
      );
    } else if (_sortBy == 'Giá: Cao → Thấp') {
      list.sort(
        (a, b) => (b['room'].price ?? 0).compareTo(a['room'].price ?? 0),
      );
    } else if (_sortBy == 'Diện tích: Lớn → Nhỏ') {
      list.sort((a, b) => (b['room'].area ?? 0).compareTo(a['room'].area ?? 0));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    // small theme tweaks for modern look
    final titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
    final subtitleStyle = TextStyle(fontSize: 14, color: Colors.grey.shade700);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?q=80&w=1000',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    padding: EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rentify ĐỒNG HÀNH CÙNG BẠN',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tặng ngay 50K',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Khi thuê phòng qua App Rentify',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: CustomSearchBar()),
                    SizedBox(width: 10),
                    InkWell(
                      onTap: () => _openFilterSheet(context),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.filter_list, color: Colors.black87),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                Row(
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
                      label: 'Tìm ở ghép',
                      color: Colors.blue,
                    ),
                    FeatureButton(
                      icon: Icons.chair,
                      label: 'Chợ thanh lý',
                      color: Colors.orange,
                    ),
                  ],
                ),
                SizedBox(height: 24),

                Row(
                  children: [
                    Icon(Icons.explore, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Text('Khám phá', style: titleStyle),
                  ],
                ),

                SizedBox(height: 12),

                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(right: 8),
                    itemCount: popularAreas.length,
                    itemBuilder: (ctx, i) => AreaCard(
                      name: popularAreas[i]['name']!,
                      imageUrl: popularAreas[i]['image']!,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                Row(
                  children: [
                    Icon(
                      Icons.apartment,
                      color: const Color.fromARGB(255, 134, 95, 36),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text('Đối tác Rentify', style: titleStyle),
                    Spacer(),
                    Text(
                      'Xem thêm',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Provider.of<RoomProvider>(
                    context,
                    listen: false,
                  ).getAvailableRoomPosts(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    if (!snapshot.hasData || snapshot.data!.isEmpty)
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Chưa có phòng trống nào'),
                        ),
                      );

                    var posts = snapshot.data!;
                    var list = filteredAndSorted(posts);

                    if (list.isEmpty)
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Không tìm thấy phòng phù hợp với bộ lọc.',
                          ),
                        ),
                      );

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        var post = list[i];
                        var room = post['room'];
                        var hostel = post['hostel'] as Hostel;
                        var address = post['address'] as Address?;

                        // Format price with dot as thousand separator
                        final priceText = room.price
                            .toInt()
                            .toString()
                            .replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (m) => '${m[1]}.',
                            );

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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: RoomPostCard(
                              title: '${room.title} - Phòng ${room.roomNumber}',
                              price: '${priceText}đ/tháng',
                              address:
                                  '${address?.street ?? ''}${address?.street != null && (address?.ward ?? '') != '' ? ', ' : ''}${address?.ward ?? ''}',
                              district: address?.city ?? 'Vinh',
                              availableRooms: 1,
                              imageUrl: room.images?.isNotEmpty == true
                                  ? room.images!.first
                                  : 'https://via.placeholder.com/150',
                              isTrusted: true,
                              ownerName: 'Đối tác',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
