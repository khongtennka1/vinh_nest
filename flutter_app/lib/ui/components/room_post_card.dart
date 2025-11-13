import 'package:flutter/material.dart';

class RoomPostCard extends StatelessWidget {
  final String title;
  final String price;
  final String address;
  final String district;
  final int availableRooms;
  final String imageUrl;
  final bool isTrusted;
  final String ownerName;

  const RoomPostCard({
    required this.title,
    required this.price,
    required this.address,
    required this.district,
    required this.availableRooms,
    required this.imageUrl,
    required this.isTrusted,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ownerName,
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      SizedBox(width: 4),
                      if (isTrusted)
                        Icon(Icons.verified, color: Colors.green, size: 16),
                    ],
                  ),
                  SizedBox(height: 4),

                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),

                  Text(
                    'Từ $price',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.home, size: 14, color: Colors.grey),
                      Text(district, style: TextStyle(fontSize: 12)),
                      Spacer(),
                      Icon(Icons.bed, size: 14, color: Colors.grey),
                      Text(
                        'Còn trống: $availableRooms phòng',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}