import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/Apartment.dart';
import 'ApartmentBooking.dart';

class ApartmentListingPage extends StatefulWidget {
  const ApartmentListingPage({super.key});

  @override
  State<ApartmentListingPage> createState() => _ApartmentListingPageState();
}

class _ApartmentListingPageState extends State<ApartmentListingPage> {
  List<Apartment> apartments = [];
  List<Apartment> filteredApartments = [];
  bool isLoading = true;

  int page = 1;
  int lastPage = 1;

  String searchTerm = '';
  String bedroomFilter = '';
  String poolFilter = '';

  final String apiUrl = '${dotenv.env['API_URL'] ?? ''}/apartments';
  final String storageUrl = dotenv.env['BASE_URL_STORAGE'] ?? '';

  @override
  void initState() {
    super.initState();
    fetchApartments(page);
  }

  Future<void> fetchApartments(int page) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiUrl?page=$page'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> dataList = jsonResponse['data'] ?? [];

        final List<Apartment> fetchedApartments =
        dataList.map((json) => Apartment.fromJson(json)).toList();

        setState(() {
          apartments = fetchedApartments;
          filteredApartments = fetchedApartments;
          this.page = jsonResponse['current_page'] ?? 1;
          lastPage = jsonResponse['last_page'] ?? 1;
        });
      } else {
        throw Exception('Failed to load apartments: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    List<Apartment> filtered = apartments;

    if (searchTerm.isNotEmpty) {
      filtered = filtered
          .where((apt) =>
          apt.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    }

    if (bedroomFilter.isNotEmpty) {
      final intBed = int.tryParse(bedroomFilter);
      if (intBed != null) {
        filtered =
            filtered.where((apt) => apt.numberOfBedroom == intBed).toList();
      }
    }

    if (poolFilter.isNotEmpty) {
      final poolBool = poolFilter == 'Yes';
      filtered =
          filtered.where((apt) => apt.swimmingPool == poolBool).toList();
    }

    setState(() {
      filteredApartments = filtered;
    });
  }

  void handlePrev() {
    if (page > 1) fetchApartments(page - 1);
  }

  void handleNext() {
    if (page < lastPage) fetchApartments(page + 1);
  }

  void showApartmentDetails(BuildContext context, Apartment apartment) {
    final PageController _photoPageController = PageController();
    int _selectedPhotoIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        apartment.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (apartment.photos.isNotEmpty) ...[
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: _photoPageController,
                            onPageChanged: (index) {
                              setState(() => _selectedPhotoIndex = index);
                            },
                            itemCount: apartment.photos.length,
                            itemBuilder: (context, index) {
                              final photo = apartment.photos[index];
                              return Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    '$storageUrl/${photo.url}',
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: apartment.photos.length,
                            itemBuilder: (context, index) {
                              final photo = apartment.photos[index];
                              return GestureDetector(
                                onTap: () {
                                  _photoPageController.jumpToPage(index);
                                  setState(() => _selectedPhotoIndex = index);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selectedPhotoIndex == index
                                          ? Colors.indigo
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      '$storageUrl/${photo.url}',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text("📍 Address: ${apartment.address}"),
                      Text("🛏 Bedrooms: ${apartment.numberOfBedroom}"),
                      Text("🏢 Floors: ${apartment.numberOfFloor}"),
                      Text("🏊‍♀️ Swimming Pool: "),
                      Text("📞 Contact:"),
                      Text("📧 Email: "),
                      const SizedBox(height: 16),
                      Text("💵 Price per Night: \$${apartment.pricePerNight?.toStringAsFixed(2) ?? 'N/A'}"),
                      Text("💰 Price per Month: \$${apartment.pricePerMonth?.toStringAsFixed(2) ?? 'N/A'}"),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.book),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookApartmentForm(apartment: apartment),
                              ),
                            );

                          },
                          label: const Text('Book Apartment'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apartment Listings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Card(
              color: Colors.indigo[600],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Apartments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        searchTerm = value;
                        applyFilters();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Search by Name',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        bedroomFilter = value;
                        applyFilters();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Filter by Bedrooms',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: poolFilter.isEmpty ? null : poolFilter,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All')),
                        DropdownMenuItem(value: 'Yes', child: Text('Has Pool')),
                        DropdownMenuItem(value: 'No', child: Text('No Pool')),
                      ],
                      onChanged: (value) {
                        poolFilter = value ?? '';
                        applyFilters();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Swimming Pool',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredApartments.isEmpty
                  ? const Center(child: Text("No apartments found."))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredApartments.length,
                itemBuilder: (context, index) {
                  final apartment = filteredApartments[index];
                  final photoUrl = apartment.photos.isNotEmpty
                      ? '$storageUrl/${apartment.photos[0].url}'
                      : null;

                  return GestureDetector(
                    onTap: () => showApartmentDetails(context, apartment),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : const AssetImage('assets/placeholder.png')
                                  as ImageProvider,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              apartment.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            Text("📍 Address: ${apartment.address}"),
                            Text("🛏 Bedrooms: ${apartment.numberOfBedroom}"),
                            Text("🏢 Floors: ${apartment.numberOfFloor}"),
                            Text("🏊‍♀️ Swimming Pool: "),
                            Text("📞 Contact:"),
                            Text("📧 Email: "),
                            const SizedBox(height: 16),
                            Text("💵 Price per Night: \$${apartment.pricePerNight?.toStringAsFixed(2) ?? 'N/A'}"),
                            Text("💰 Price per Month: \$${apartment.pricePerMonth?.toStringAsFixed(2) ?? 'N/A'}"),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
