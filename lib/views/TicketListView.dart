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
      final url = Uri.parse(
        '${dotenv.env['API_URL'] ?? ''}/journeys?page=$pageNum&limit=$limit',
      );
      final response = await http.get(url);

      if (response.statusCode != 200)
        throw Exception('Failed to fetch journeys');
      final json = jsonDecode(response.body);

      List data = json['data'];
      List<String> agencyNames =
          data
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
    List result =
        journeys.where((j) {
          final from = j['from']?.toLowerCase() ?? '';
          final to = j['to']?.toLowerCase() ?? '';
          final agency = j['bus']?['agency']?['name']?.toLowerCase() ?? '';
          final departure = j['departure']?.substring(0, 10) ?? '';

          final matchesSearch =
              search.isEmpty ||
              from.contains(search.toLowerCase()) ||
              to.contains(search.toLowerCase()) ||
              agency.contains(search.toLowerCase());

          final matchesAgency =
              selectedAgency.isEmpty || agency == selectedAgency.toLowerCase();
          final matchesDate =
              departureDate.isEmpty || departure == departureDate;

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
            Text(
              '${journey['from']} ➡️ ${journey['to']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Agency: ${journey['bus']?['agency']?['name'] ?? '—'}'),
            Text(
              'Bus: ${journey['bus']?['name'] ?? '—'} (${layout?['name'] ?? ''})',
            ),
            Text('Departure: ${journey['departure']}'),
            Text('Return: ${journey['return']}'),
            Text('Status: ${journey['status'] ?? 'Inactive'}'),
            SizedBox(height: 10),
            Text(
              '${journey['price'] ?? 0} RWF',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                  decoration: InputDecoration(
                    labelText: 'Search by route or agency',
                  ),
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
                  items:
                      agencies.map((agency) {
                        return DropdownMenuItem(
                          value: agency,
                          child: Text(agency),
                        );
                      }).toList(),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Departure Date (YYYY-MM-DD)',
                  ),
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
              child:
                  loading
                      ? Center(child: CircularProgressIndicator())
                      : filteredJourneys.isEmpty
                      ? Center(child: Text('No journeys match your criteria.'))
                      : ListView(
                        children:
                            filteredJourneys.map((j) => buildCard(j)).toList(),
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
                  onPressed:
                      page < lastPage ? () => fetchJourneys(page + 1) : null,
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

class BookNowForm extends StatefulWidget {
  final Map journey;
  BookNowForm({required this.journey});

  @override
  _BookNowFormState createState() => _BookNowFormState();
}

class _BookNowFormState extends State<BookNowForm> {
  final _formKey = GlobalKey<FormState>();
  final String apiUrl = dotenv.env['API_URL'] ?? '';

  String fullName = '';
  String email = '';
  String address = '';
  String phoneNumber = '';
  String selectedSeat = '';
  String otp = '';

  String step = "form";
  bool isSending = false;
  bool isVerifying = false;

  String selectedCountry = 'Rwanda';
  String selectedPaymentMethod = '';
  String momoNumber = '';

  final int seatRows = 9;
  final int seatColumns = 5;
  final List<int> excludedSeats = [
    1, 2, 3, 4, 5,
    10, 9, 8,
    13, 18, 23, 28, 33, 38,
  ];

  Future<void> sendOTP() async {
    setState(() => isSending = true);
    try {
      final res = await http.post(
        Uri.parse('$apiUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode != 200) throw Exception("Failed to send OTP");
      setState(() => step = "otp");
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP')),
      );
      print(err);
    } finally {
      setState(() => isSending = false);
    }
  }

  Future<void> verifyOTPAndBook() async {
    setState(() => isVerifying = true);
    try {
      final verifyRes = await http.post(
        Uri.parse('$apiUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (verifyRes.statusCode != 200) throw Exception("Invalid OTP");

      final bookingData = {
        'names': fullName,
        'email': email,
        'address': address,
        'phone': phoneNumber,
        'seat': selectedSeat,
        'journey': widget.journey,
        'object_type': 'ticket',
        'object_id': widget.journey['id'],
        'amount_to_pay': widget.journey['price'],
        'payment_method': selectedPaymentMethod,
        'momo_number': momoNumber,
        'country': selectedCountry,
      };

      final bookingRes = await http.post(
        Uri.parse('$apiUrl/booking/ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingData),
      );



      if (bookingRes.statusCode != 201) throw Exception("Booking failed");

      setState(() => step = "success");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Booking Successful"),
            content: Text("Your booking was successful! A payment link has been sent to your email."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pop(context); // Optionally pop the booking page
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );


    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification or booking failed')),
      );
      print(err);
    } finally {
      setState(() => isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;

    return Scaffold(
      appBar: AppBar(title: Text('Book Now')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: step == "form"
            ? Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Book a Seat for ${journey['from']} ➡️ ${journey['to']}',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (val) =>
                val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => fullName = val!,
              ),

              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (val) =>
                val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => email = val!,
              ),

              TextFormField(
                decoration: InputDecoration(labelText: 'Address'),
                validator: (val) =>
                val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => address = val!,
              ),

              TextFormField(
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) =>
                val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => phoneNumber = val!,
              ),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Country'),
                value: selectedCountry,
                items: [
                  'Rwanda',
                  'Kenya',
                  'Uganda',
                  'Tanzania',
                  'Burundi',
                  'South Sudan',
                  'Ethiopia',
                  'Somalia',
                  'Democratic Republic of Congo',
                  'Republic of Congo',
                  'Nigeria',
                  'Ghana',
                  'South Africa',
                  'Zimbabwe',
                  'Zambia',
                  'Malawi',
                  'Botswana',
                  'Namibia',
                  'Lesotho',
                  'Eswatini',
                  'Mozambique',
                  'Angola',
                  'Cameroon',
                  'Chad',
                  'Central African Republic',
                  'Mali',
                  'Niger',
                  'Burkina Faso',
                  'Togo',
                  'Benin',
                  'Ivory Coast',
                  'Sierra Leone',
                  'Liberia',
                  'Guinea',
                  'Gambia',
                  'Senegal',
                  'Mauritania',
                  'Algeria',
                  'Tunisia',
                  'Morocco',
                  'Egypt',
                  'Sudan',
                  'Eritrea',
                  'Libya',
                  'Cape Verde',
                  'Seychelles',
                  'Mauritius',
                  'Comoros',
                  'Djibouti'
                ]
                    .map((country) => DropdownMenuItem(
                  value: country,
                  child: Text(country),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCountry = value!;
                  });
                },
                validator: (val) =>
                val == null ? 'Select a country' : null,
              ),

              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Payment Method'),
                value: selectedPaymentMethod.isNotEmpty
                    ? selectedPaymentMethod
                    : null,
                items: [
                  DropdownMenuItem(
                    value: 'momo_rwanda',
                    child: Text('MTN Mobile Money (Rwanda)'),
                  ),
                  DropdownMenuItem(
                    value: 'flutterwave',
                    child: Text('Flutterwave - Wallet,Card, bank'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
                validator: (val) =>
                val == null ? 'Select a payment method' : null,
              ),

              if (selectedPaymentMethod == 'momo_rwanda')
                TextFormField(
                  decoration:
                  InputDecoration(labelText: 'MTN Momo Number'),
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (selectedPaymentMethod == 'MTN_MOMO' &&
                        (val == null || val.isEmpty)) {
                      return 'Enter Momo Number';
                    }
                    return null;
                  },
                  onSaved: (val) => momoNumber = val!,
                ),

              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedSeat.isNotEmpty
                        ? 'Selected Seat: $selectedSeat'
                        : 'No seat selected',
                    style: TextStyle(fontSize: 16),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final seat = await Navigator.push<int>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeatSelectionScreen(
                            seatRows: seatRows,
                            seatColumns: seatColumns,
                            excludedSeats: excludedSeats,
                            objectId: widget.journey['id'],
                          ),
                        ),
                      );
                      if (seat != null) {
                        setState(() {
                          selectedSeat = seat.toString();
                        });
                      }
                    },
                    child: Text('Select Seat'),
                  ),
                ],
              ),

              SizedBox(height: 16),

              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    if (selectedSeat.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select a seat'),
                        ),
                      );
                      return;
                    }
                    _formKey.currentState!.save();
                    sendOTP();
                  }
                },
                child: isSending
                    ? CircularProgressIndicator()
                    : Text('Send OTP'),
              ),
            ],
          ),
        )
            : step == "otp"
            ? Column(
          children: [
            Text('Enter OTP sent to $email'),
            SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'OTP'),
              onChanged: (val) => otp = val,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isVerifying ? null : verifyOTPAndBook,
              child: isVerifying
                  ? CircularProgressIndicator()
                  : Text('Verify & Confirm Booking'),
            ),
          ],
        )
            : Center(child: Text("Booking completed successfully!")),
      ),
    );
  }
}

// Replace with your actual API base URL





class SeatSelectionScreen extends StatefulWidget {
  final int seatRows;
  final int seatColumns;
  final int objectId;
  final List<int> excludedSeats;

  const SeatSelectionScreen({
    required this.seatRows,
    required this.seatColumns,
    required this.objectId,
    required this.excludedSeats,
    super.key,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  bool isLoading = true;
  List<int> bookedSeats = [];

  @override
  void initState() {
    super.initState();
    fetchBookedSeats();
  }

  Future<void> fetchBookedSeats() async {
    try {
      final String apiUrl = dotenv.env['API_URL'] ?? '';
      final uri = Uri.parse('$apiUrl/booked-seats/${widget.objectId}');
      final response = await http.get(uri);
       print(response.body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('booked seats: $jsonData');

        List<dynamic> seats = jsonData is List ? jsonData : jsonData['booked_seats'];
        setState(() {
          bookedSeats = seats.map<int>((s) => int.tryParse(s.toString()) ?? 0).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load booked seats');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading seats: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<Widget> seatButtons = [];
    for (int row = 0; row < widget.seatRows; row++) {
      for (int col = 0; col < widget.seatColumns; col++) {
        int seatNumber = row * widget.seatColumns + col + 1;
        bool isExcluded = widget.excludedSeats.contains(seatNumber) || bookedSeats.contains(seatNumber);

        seatButtons.add(
          Padding(
            padding: const EdgeInsets.all(4),
            child: ElevatedButton(
              onPressed: isExcluded
                  ? null
                  : () {
                Navigator.pop(context, seatNumber);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isExcluded ? Colors.grey : Colors.blue,
                minimumSize: const Size(40, 40),
              ),
              child: Text('$seatNumber'),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select a Seat')),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: seatButtons,
        ),
      ),
    );
  }
}




class ChoosePaymentMethodScreen extends StatefulWidget {
  const ChoosePaymentMethodScreen({super.key});

  @override
  ChoosePaymentMethodScreenState createState() => ChoosePaymentMethodScreenState();
}

class ChoosePaymentMethodScreenState extends State<ChoosePaymentMethodScreen> {
  String selectedPaymentMethod = '';
  String momoNumber = '';
  String extraNote = '';
  bool isSending = false;

  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose Payment Method')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Choose Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedPaymentMethod.isEmpty ? null : selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text('-- Select Payment Method --')),
                  DropdownMenuItem(value: 'momo_rwanda', child: Text('MOMO (MTN Rwanda)')),
                  DropdownMenuItem(value: 'flutterwave', child: Text('Flutterwave (MOMO, Airtel, Card, Bank Transfer)')),
                ],
                validator: (value) => (value == null || value.isEmpty) ? 'Please select a payment method' : null,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value ?? '';
                  });
                },
              ),

              if (selectedPaymentMethod == 'momo_rwanda') ...[
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'MoMo Phone Number',
                    hintText: 'e.g., 2507XXXXXXXX',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'Enter MoMo Number' : null,
                  onChanged: (val) => momoNumber = val,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Additional Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (val) => extraNote = val,
                ),
              ],

              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // or go to previous step
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: Text('Back'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(isSending ? 'Sending OTP...' : 'Continue'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

