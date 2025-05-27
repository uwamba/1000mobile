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
      final url = Uri.parse('${dotenv.env['API_URL'] ?? ''}/rooms/${widget.roomId}');
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

  Widget buildInfoItem(String label, dynamic value) {
    return Text('$label: ${value ?? 'N/A'}', style: TextStyle(fontSize: 14));
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Image Display
            AspectRatio(
              aspectRatio: 16 / 9,
              child: photos.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: '$storageUrl/${photos[selectedImageIndex]['path']}',
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              )
                  : Image.asset(
                'assets/placeholder/placeholder.png',
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(height: 10),

            // Thumbnails
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
                        margin: EdgeInsets.symmetric(horizontal: 5),
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

            SizedBox(height: 16),

            // Room Info
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInfoItem('Type', room!['type']),
                    buildInfoItem('Bed Size', room!['bed_size']),
                    buildInfoItem('Price', '${room!['price']} ${room!['currency']}'),
                    buildInfoItem('Capacity', '${room!['number_of_people']} people'),
                    buildInfoItem('WiFi', room!['has_wireless'] ? 'Yes' : 'No'),
                    buildInfoItem('Bathroom', room!['has_bathroom'] ? 'Yes' : 'No'),
                    buildInfoItem('Air Conditioning', room!['has_ac'] ? 'Yes' : 'No'),
                    buildInfoItem('Status', room!['status']),
                    if (room!['hotel'] != null) buildInfoItem('Hotel', room!['hotel']['name']),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Booking Form Placeholder
            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingForm(),
                  ),
                );
              },
              child: Text('Book This Room'),
            ),

            SizedBox(height: 32),

            // Similar Rooms
            if (similarRooms.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Similar Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ...similarRooms.map((room) {
                    final imgUrl = room['photos'] != null && room['photos'].isNotEmpty
                        ? '$storageUrl/${room['photos'][0]['path']}'
                        : null;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: imgUrl != null
                            ? CachedNetworkImage(
                          imageUrl: imgUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        )
                            : Image.asset(
                          'assets/placeholder/placeholder.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(room['name']),
                        subtitle: Text('Price: ${room['price']} ${room['currency']}'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingForm(),
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
