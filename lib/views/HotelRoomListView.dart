import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'HotelRoomDetailsView.dart';

class HotelRoomListView extends StatefulWidget {
  const HotelRoomListView({super.key});

  @override
  RoomListClientPageState createState() => RoomListClientPageState();
}

class RoomListClientPageState extends State<HotelRoomListView> {
  List<dynamic> rooms = [];
  List<dynamic> filteredRooms = [];
  bool loading = true;
  int page = 1;
  int lastPage = 1;

  String minPrice = '';
  String maxPrice = '';
  DateTime? checkinDate;
  DateTime? checkoutDate;

  final String storageUrl = dotenv.env['BASE_URL_STORAGE'] ?? '';
  final String apiUrl = '${dotenv.env['API_URL'] ?? ''}/client/rooms';

  @override
  void initState() {
    super.initState();
    fetchRooms(page);
  }

  Future<void> fetchRooms(int page) async {
    setState(() => loading = true);

    try {
      final uri = Uri.parse(apiUrl).replace(queryParameters: {
        'page': page.toString(),
        if (checkinDate != null) 'from_date': checkinDate!.toIso8601String().substring(0, 10),
        if (checkoutDate != null) 'to_date': checkoutDate!.toIso8601String().substring(0, 10),
        if (minPrice.isNotEmpty) 'min_price': minPrice,
        if (maxPrice.isNotEmpty) 'max_price': maxPrice,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          rooms = jsonData['data'];
          print(rooms);
          filteredRooms = jsonData['data'];
          this.page = jsonData['current_page'];
          lastPage = jsonData['last_page'];
        });
      } else {
        print("Failed to fetch rooms: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching rooms: $e");
    }

    setState(() => loading = false);
  }

  void applyFilters() {
    List<dynamic> filtered = rooms;



    setState(() {
      filteredRooms = filtered;
    });
  }

  void handlePrev() {
    if (page > 1) fetchRooms(page - 1);
  }

  void handleNext() {
    if (page < lastPage) fetchRooms(page + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Filter Form
            Card(
              color: Colors.blue[600],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter Rooms',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 16),

                    Text("Check-in & Check-out", style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => checkinDate = picked);
                              }
                            },
                            child: Text(checkinDate == null
                                ? "Check-in"
                                : checkinDate!.toIso8601String().substring(0, 10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: checkinDate?.add(const Duration(days: 1)) ?? DateTime.now(),
                                firstDate: checkinDate ?? DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => checkoutDate = picked);
                              }
                            },
                            child: Text(checkoutDate == null
                                ? "Check-out"
                                : checkoutDate!.toIso8601String().substring(0, 10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) => minPrice = value,
                      decoration: const InputDecoration(
                        labelText: 'Min Price',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) => maxPrice = value,
                      decoration: const InputDecoration(
                        labelText: 'Max Price',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => fetchRooms(1),
                      child: const Text("Apply Filters"),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Room Grid
            Expanded(
              child: filteredRooms.isEmpty
                  ? const Center(child: Text("No rooms found."))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredRooms.length,
                itemBuilder: (context, index) {
                  final room = filteredRooms[index];
                  final photoPath = room['photos'].isNotEmpty
                      ? '$storageUrl/${room['photos'][0]['path']}'
                      : null;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomDetailScreen(roomId: room['id'].toString()),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: photoPath != null
                                      ? NetworkImage(photoPath)
                                      : const AssetImage('assets/placeholder/placeholder.png')
                                  as ImageProvider,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              room['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(room['description'] ?? ''),
                            Text('Price: \$${room['price']}'),
                            Text('Capacity: ${room['capacity']} people'),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${room['status'] ?? 'N/A'}',
                              style: TextStyle(
                                color: room['status'] == 'available' ? Colors.green : Colors.red,
                              ),
                            ),
                            if (room['deleted_on'] != null)
                              Text(
                                'Deleted on: ${room['deleted_on']}',
                                style: const TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Pagination Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: page == 1 ? null : handlePrev,
                  child: const Text("Previous"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Page $page of $lastPage"),
                ),
                ElevatedButton(
                  onPressed: page == lastPage ? null : handleNext,
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
