import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'RoomBooking.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  Map<String, dynamic>? room;
  List<dynamic> similarRooms = [];
  int selectedImageIndex = 0;
  bool loading = true;

  final String storageUrl = dotenv.env['BASE_URL_STORAGE'] ?? '';

  @override
  void initState() {
    super.initState();
    fetchRoomDetails();
  }

  Future<void> fetchRoomDetails() async {
    try {
      final url = Uri.parse('${dotenv.env['API_URL'] ?? ''}/client/rooms/${widget.roomId}');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          room = data['room'];
          similarRooms = data['similarRooms'] ?? [];
        });
      } else {
        throw Exception('Failed to load room');
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget buildIconInfo(IconData icon, String label, dynamic value, double width) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    )),
                const SizedBox(height: 2),
                Text(value?.toString() ?? 'N/A',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (room == null) {
      return Scaffold(
        body: Center(child: Text('Room not found.', style: TextStyle(color: Colors.red))),
      );
    }

    final photos = room!['photos'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(room!['name'] ?? 'Room Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Main Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: photos.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: '$storageUrl/${photos[selectedImageIndex]['path']}',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
                  : Image.asset(
                'assets/placeholder/placeholder.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),

            /// Thumbnails
            if (photos.length > 1)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedImageIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: index == selectedImageIndex ? Colors.blue : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: '$storageUrl/${photos[index]['path']}',
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            /// Room Info Card
            /// Room Info Card - Two Column Layout
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columnWidth = constraints.maxWidth / 2 - 16;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        buildIconInfo(Icons.hotel, 'Type', room!['type'], columnWidth),
                        buildIconInfo(Icons.bed, 'Bed Size', room!['bed_size'], columnWidth),
                        buildIconInfo(Icons.price_change, 'Price', '${room!['price']} ${room!['currency']}', columnWidth),
                        buildIconInfo(Icons.people, 'Capacity', '${room!['number_of_people']} people', columnWidth),
                        buildIconInfo(Icons.wifi, 'WiFi', room!['has_wireless'] ? 'Yes' : 'No', columnWidth),
                        buildIconInfo(Icons.bathtub, 'Bathroom', room!['has_bathroom'] ? 'Yes' : 'No', columnWidth),
                        buildIconInfo(Icons.ac_unit, 'Air Conditioning', room!['has_ac'] ? 'Yes' : 'No', columnWidth),
                        buildIconInfo(Icons.verified, 'Status', room!['status'], columnWidth),
                        if (room!['hotel'] != null)
                          buildIconInfo(Icons.location_city, 'Hotel', room!['hotel']['name'], columnWidth),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Book Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookRoomForm(room: room!),
                    ),
                  );
                },
                icon: const Icon(Icons.book_online),
                label: const Text('Book This Room'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 32),

            /// Similar Rooms Section
            if (similarRooms.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Similar Rooms',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...similarRooms.map((similarRoom) {
                    final imgUrl = similarRoom['photos'] != null &&
                        similarRoom['photos'].isNotEmpty
                        ? '$storageUrl/${similarRoom['photos'][0]['path']}'
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: imgUrl != null
                            ? CachedNetworkImage(
                          imageUrl: imgUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                        )
                            : Image.asset(
                          'assets/placeholder/placeholder.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(similarRoom['name']),
                        subtitle: Text(
                            'Price: ${similarRoom['price']} ${similarRoom['currency']}'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookRoomForm(room: similarRoom),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
