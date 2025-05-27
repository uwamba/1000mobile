import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
class TicketListView extends StatefulWidget {
  const TicketListView({super.key});

  @override
  BusListScreenState createState() => BusListScreenState();
}

class BusListScreenState extends State<TicketListView> {
  List journeys = [];
  List filteredJourneys = [];
  List<String> agencies = [];

  String search = '';
  String selectedAgency = '';
  String departureDate = '';
  int page = 1;
  int lastPage = 1;
  final int limit = 20;
  bool loading = true;


  @override
  void initState() {
    super.initState();
    fetchJourneys(page);
  }

  Future<void> fetchJourneys(int pageNum) async {
    setState(() => loading = true);
    try {
      final url = Uri.parse('${dotenv.env['API_URL'] ?? ''}/journeys?page=$pageNum&limit=$limit');
      final response = await http.get(url);

      if (response.statusCode != 200) throw Exception('Failed to fetch journeys');
      final json = jsonDecode(response.body);

      List data = json['data'];
      List<String> agencyNames = data
          .map((j) => j['bus']?['agency']?['name'])
          .where((name) => name != null)
          .toSet()
          .cast<String>()
          .toList();

      setState(() {
        journeys = data;
        filteredJourneys = data;
        agencies = agencyNames;
        page = json['current_page'];
        lastPage = json['last_page'];
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void applyFilters() {
    List result = journeys.where((j) {
      final from = j['from']?.toLowerCase() ?? '';
      final to = j['to']?.toLowerCase() ?? '';
      final agency = j['bus']?['agency']?['name']?.toLowerCase() ?? '';
      final departure = j['departure']?.substring(0, 10) ?? '';

      final matchesSearch = search.isEmpty ||
          from.contains(search.toLowerCase()) ||
          to.contains(search.toLowerCase()) ||
          agency.contains(search.toLowerCase());

      final matchesAgency = selectedAgency.isEmpty || agency == selectedAgency.toLowerCase();
      final matchesDate = departureDate.isEmpty || departure == departureDate;

      return matchesSearch && matchesAgency && matchesDate;
    }).toList();

    setState(() {
      filteredJourneys = result;
    });
  }

  Widget buildCard(journey) {
    final layout = journey['bus']?['layout'];
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${journey['from']} ➡️ ${journey['to']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Agency: ${journey['bus']?['agency']?['name'] ?? '—'}'),
            Text('Bus: ${journey['bus']?['name'] ?? '—'} (${layout?['name'] ?? ''})'),
            Text('Departure: ${journey['departure']}'),
            Text('Return: ${journey['return']}'),
            Text('Status: ${journey['status'] ?? 'Inactive'}'),
            SizedBox(height: 10),
            Text('${journey['price'] ?? 0} RWF', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BookNowForm(journey: journey),
                );
              },
              child: Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Journeys")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters
            Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Search by route or agency'),
                  onChanged: (val) {
                    search = val;
                    applyFilters();
                  },
                ),
                DropdownButton<String>(
                  value: selectedAgency.isEmpty ? null : selectedAgency,
                  hint: Text("Select Agency"),
                  onChanged: (val) {
                    selectedAgency = val ?? '';
                    applyFilters();
                  },
                  isExpanded: true,
                  items: agencies.map((agency) {
                    return DropdownMenuItem(value: agency, child: Text(agency));
                  }).toList(),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Departure Date (YYYY-MM-DD)'),
                  onChanged: (val) {
                    departureDate = val;
                    applyFilters();
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      search = '';
                      selectedAgency = '';
                      departureDate = '';
                      filteredJourneys = journeys;
                    });
                  },
                  child: Text('Clear Filters'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // List or Loading
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : filteredJourneys.isEmpty
                  ? Center(child: Text('No journeys match your criteria.'))
                  : ListView(
                children: filteredJourneys.map((j) => buildCard(j)).toList(),
              ),
            ),

            // Pagination
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: page > 1 ? () => fetchJourneys(page - 1) : null,
                  child: Text("Previous"),
                ),
                SizedBox(width: 16),
                Text("Page $page of $lastPage"),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: page < lastPage ? () => fetchJourneys(page + 1) : null,
                  child: Text("Next"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class BookNowForm extends StatefulWidget {
  final Map journey;

  BookNowForm({required this.journey});

  @override
  _BookNowFormState createState() => _BookNowFormState();
}

class _BookNowFormState extends State<BookNowForm> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String phoneNumber = '';
  String selectedSeat = '';

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Book a Seat for ${journey['from']} ➡️ ${journey['to']}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  onSaved: (val) => fullName = val!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  onSaved: (val) => phoneNumber = val!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Seat Number'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  onSaved: (val) => selectedSeat = val!,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      // Send booking data to API or state management
                      print('Booking: $fullName, $phoneNumber, Seat: $selectedSeat');

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Booking Submitted!')),
                      );
                    }
                  },
                  child: Text('Confirm Booking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

