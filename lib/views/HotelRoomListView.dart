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

  String searchTerm = '';
  String capacityFilter = '';
  String statusFilter = '';


  final String storageUrl = dotenv.env['BASE_URL_STORAGE'] ?? '';

  final String apiUrl = '${dotenv.env['API_URL'] ?? ''}/rooms';

  @override
  void initState() {
    super.initState();
    fetchRooms(page);
  }

  Future<void> fetchRooms(int page) async {
    setState(() => loading = true);

    try {
      final response = await http.get(Uri.parse('$apiUrl?page=$page'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        setState(() {
          rooms = jsonData['data'];
          filteredRooms = jsonData['data'];
          this.page = jsonData['current_page'];
          lastPage = jsonData['last_page'];
        });
      } else {
        print("Failed to fetch rooms");
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() => loading = false);
  }

  void applyFilters() {
    List<dynamic> filtered = rooms;

    if (searchTerm.isNotEmpty) {
      filtered = filtered
          .where((room) =>
          room['name'].toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    }

    if (capacityFilter.isNotEmpty) {
      final intCap = int.tryParse(capacityFilter);
      if (intCap != null) {
        filtered =
            filtered.where((room) => room['capacity'] == intCap).toList();
      }
    }

    if (statusFilter.isNotEmpty) {
      filtered = filtered
          .where((room) => room['status'] == statusFilter)
          .toList();
    }

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
      appBar: AppBar(
        title: Text('Room List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Filter section
            Card(
              color: Colors.blue[600],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Rooms',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          searchTerm = value;
                          applyFilters();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Search by Name',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          capacityFilter = value;
                          applyFilters();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Filter by Capacity',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: statusFilter.isEmpty ? null : statusFilter,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All')),
                        DropdownMenuItem(value: 'available', child: Text('Available')),
                        DropdownMenuItem(value: 'unavailable', child: Text('Unavailable')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          statusFilter = value ?? '';
                          applyFilters();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Status',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Room cards
            Expanded(
              child: filteredRooms.isEmpty
                  ? Center(child: Text("No rooms found."))
                  : GridView.builder(
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                  MediaQuery.of(context).size.width > 800
                      ? 3
                      : 1,
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
                          mainAxisSize: MainAxisSize.min, // This ensures height fits content
                          children: [
                            Container(
                              height: 200, // Increased image height
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
                                color: room['status'] == 'available'
                                    ? Colors.green
                                    : Colors.red,
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

            // Pagination controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: page == 1 ? null : handlePrev,
                  child: Text("Previous"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Page $page of $lastPage"),
                ),
                ElevatedButton(
                  onPressed: page == lastPage ? null : handleNext,
                  child: Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
