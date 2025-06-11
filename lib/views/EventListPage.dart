import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'EventBooking.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  EventListPageState createState() => EventListPageState();
}

class EventListPageState extends State<EventListPage> {
  List<dynamic> retreats = [];
  int page = 1;
  int lastPage = 1;
  bool loading = true;
  dynamic selectedRetreat;
  int selectedPhotoIndex = 0;

  DateTime? fromDate;
  DateTime? toDate;


  final String imageBaseUrl = dotenv.env['BASE_URL_STORAGE'] ?? '';
  final String baseUrl = '${dotenv.env['API_URL'] ?? ''}';


  @override
  void initState() {
    super.initState();
    fetchRetreats(page);
  }

  Future<void> fetchRetreats(int page) async {
    setState(() => loading = true);

    try {
      final queryParams = {
        'page': page.toString(),
        if (fromDate != null) 'from_date': fromDate!.toIso8601String().split('T')[0],
        if (toDate != null) 'to_date': toDate!.toIso8601String().split('T')[0],
      };

      final uri = Uri.parse('$baseUrl/client/retreats').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          if (page == 1) {
            retreats = jsonData['data'];
          } else {
            retreats.addAll(jsonData['data']);
          }
          this.page = jsonData['current_page'];
          lastPage = jsonData['last_page'];
        });
      }
    } catch (e) {
      print('Error fetching retreats: $e');
    } finally {
      setState(() => loading = false);
    }
  }


  void openModal(dynamic retreat) {
    setState(() {
      selectedRetreat = retreat;
      selectedPhotoIndex = 0;
    });
    showDialog(
      context: context,
      builder: (_) => retreatDetailModal(),
    );
  }

  void handleBookNow(dynamic retreat) {
    print('Booking: $retreat');
  }

  Widget retreatDetailModal() {
    return Dialog(
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [

                SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedRetreat['title'],
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(selectedRetreat['address'],
                    style: TextStyle(color: Colors.grey[700])),
                SizedBox(height: 16),
                if (selectedRetreat['photos'] != null &&
                    selectedRetreat['photos'].isNotEmpty)
                  Column(
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey)),
                        child: Image.network(
                          '$imageBaseUrl/${selectedRetreat['photos'][selectedPhotoIndex]['path']}',
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(
                            selectedRetreat['photos'].length, (index) {
                          final photo = selectedRetreat['photos'][index];
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedPhotoIndex = index;
                              });
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: index == selectedPhotoIndex
                                      ? Colors.indigo
                                      : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: Image.network(
                                '$imageBaseUrl/${photo['path']}',
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Title: ${selectedRetreat['title']}'),
                    Text('Address: ${selectedRetreat['address']}'),
                    Text('Description: ${selectedRetreat['description']}'),
                    Text(
                      'Status: ${selectedRetreat['status'] ?? 'N/A'}',
                      style: TextStyle(
                        color: selectedRetreat['status'] == 'active'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (selectedRetreat['deleted_on'] != null)
                      Text('Deleted On: ${selectedRetreat['deleted_on']}'),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventRoomForm(event: selectedRetreat!),
                      ),
                    );
                  },
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('Book Now'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event and Meeting Space'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading && page == 1
            ? Center(child: CircularProgressIndicator())
            : retreats.isEmpty
            ? Center(child: Text('No retreats found.'))
            : Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50], // light blue background for container
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fromDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => fromDate = picked);
                              fetchRetreats(1); // refetch on date change
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[900]!),
                            ),
                            child: Text(
                              fromDate != null
                                  ? "From: ${fromDate!.toLocal().toString().split(' ')[0]}"
                                  : "Select From Date",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: toDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => toDate = picked);
                              fetchRetreats(1); // refetch on date change
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[900]!),
                            ),
                            child: Text(
                              toDate != null
                                  ? "To: ${toDate!.toLocal().toString().split(' ')[0]}"
                                  : "Select To Date",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(12),
                itemCount: retreats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7, // tweak if needed
                ),
                itemBuilder: (context, index) {
                  final retreat = retreats[index];
                  final photoUrl = (retreat['photos']?.isNotEmpty ?? false)
                      ? '$imageBaseUrl/${retreat['photos'][0]['path']}'
                      : 'https://via.placeholder.com/150';

                  return Card(
                    elevation: 4,
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  retreat['title'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  retreat['address'],
                                  style: TextStyle(color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Text('Price per Person: \$${retreat['price_per_person'] ?? 'N/A'}'),
                                Text('Package Price: \$${retreat['package_price'] ?? 'N/A'}'),
                                Text('Capacity: ${retreat['capacity'] ?? 'N/A'}'),
                                Text('Pricing Type: ${retreat['pricing_type'] ?? 'N/A'}'),
                                Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => openModal(retreat),
                                    child: Text('See More Details'),
                                    style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(36)),
                                  ),
                                ),
                              ],

                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                },
              ),
            ),

            if (page < lastPage)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (!loading) fetchRetreats(page + 1);
                  },
                  child: loading ? CircularProgressIndicator() : Text('Show More'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
