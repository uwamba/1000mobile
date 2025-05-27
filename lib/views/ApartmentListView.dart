import 'package:flutter/material.dart';
import 'package:visit_1000_hills/services/ApartmentService.dart';

import 'ApartmentDetailsView.dart';
// Ensure this import exists

class ApartmentListView extends StatefulWidget {
  const ApartmentListView({super.key});

  @override
  ApartmentListViewState createState() => ApartmentListViewState();
}

class ApartmentListViewState extends State<ApartmentListView> {
  String? selectedApartmentType;
  String? selectedLocation;
  double minPrice = 0;
  double maxPrice = 1000;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final apartments =
        ApartmentService.getApartments().where((apartment) {
          bool matchesType =
              selectedApartmentType == null ||
              apartment.apartmentType == selectedApartmentType;
          bool matchesLocation =
              selectedLocation == null ||
              apartment.location == selectedLocation;
          bool matchesPrice =
              apartment.price >= minPrice && apartment.price <= maxPrice;
          bool matchesSearch =
              searchQuery.isEmpty ||
              apartment.name.toLowerCase().contains(searchQuery.toLowerCase());
          return matchesType &&
              matchesLocation &&
              matchesPrice &&
              matchesSearch;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartments'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by apartment name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'Type',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: selectedApartmentType,
                        items:
                            ['Studio', '1 Bedroom', '2 Bedroom', '3 Bedroom']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedApartmentType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'Location',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: selectedLocation,
                        items:
                            ['Downtown', 'Suburbs', 'Countryside']
                                .map(
                                  (location) => DropdownMenuItem(
                                    value: location,
                                    child: Text(location),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLocation = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(minPrice, maxPrice),
                  min: 0,
                  max: 1000,
                  divisions: 10,
                  labels: RangeLabels(
                    '\$${minPrice.round()}',
                    '\$${maxPrice.round()}',
                  ),
                  onChanged: (values) {
                    setState(() {
                      minPrice = values.start;
                      maxPrice = values.end;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: apartments.length,
        itemBuilder: (context, index) {
          final apartment = apartments[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ApartmentDetailsView(
                        apartment: apartment,
                      ), // `apartment` is of type Apartment
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        image: DecorationImage(
                          image: AssetImage(apartment.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apartment.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Location
                          Text(
                            apartment.location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Price per Month
                          Text(
                            '\$${apartment.price.toStringAsFixed(2)} / month',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),

                    

                          // Apartment Type
                          Text(
                            'Apartment Type: ${apartment.apartmentType}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),

                        
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
