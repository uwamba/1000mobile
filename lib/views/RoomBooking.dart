import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BookRoomForm extends StatefulWidget {
  final Map<String, dynamic> room;

  const BookRoomForm({required this.room, super.key});

  @override
  BookNowFormState createState() => BookNowFormState();
}

class BookNowFormState extends State<BookRoomForm> {
  final _formKey = GlobalKey<FormState>();
  final String apiUrl = dotenv.env['API_URL'] ?? '';

  String fullName = '';
  String email = '';
  String address = '';
  String phoneNumber = '';
  String otp = '';

  String step = "form";
  bool isSending = false;
  bool isVerifying = false;

  String selectedCountry = 'Rwanda';
  String selectedPaymentMethod = '';
  String momoNumber = '';

  DateTime? from_date_time;
  DateTime? to_date_time;

  int get daysStayed {
    if (from_date_time != null && to_date_time != null) {
      return to_date_time!.difference(from_date_time!).inDays;
    }
    return 0;
  }

  double get totalAmount {
    return (daysStayed > 0 ? daysStayed : 0) *
        (widget.room['price'] as num).toDouble();
  }

  Future<void> pickDate({required bool isCheckIn}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          from_date_time = picked;
          if (to_date_time != null && from_date_time!.isBefore(picked)) {
            to_date_time = null;
          }
        } else {
          to_date_time = picked;
        }
      });
    }
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending OTP')));
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
        'journey': widget.room,
        'object_type': 'room',
        'object_id': widget.room['id'],
        'from_date_time': from_date_time!.toIso8601String(),
        'to_date_time': to_date_time!.toIso8601String(),
        'amount_to_pay': totalAmount,
        'payment_method': selectedPaymentMethod,
        'momo_number': momoNumber,
        'country': selectedCountry,
      };

      final bookingRes = await http.post(
        Uri.parse('$apiUrl/bookings'),
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
            content: Text(
              "Your booking was successful! A payment link has been sent to your email.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verification or booking failed')));
      print(err);
    } finally {
      setState(() => isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.room;

    return Scaffold(
      appBar: AppBar(title: Text('Book Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            step == "form"
                ? Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🛏️ Book Room at ${journey['location'] ?? 'Hotel'}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Full Name
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => fullName = val!,
                      ),
                      SizedBox(height: 16),

                      // Email
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => email = val!,
                      ),
                      SizedBox(height: 16),

                      // Address
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.location_on),
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => address = val!,
                      ),
                      SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.phone),
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => phoneNumber = val!,
                      ),
                      SizedBox(height: 16),

                      // Country
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.flag),
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedCountry,
                        items:
                            ['Rwanda', 'Kenya', 'Uganda'].map((country) {
                              return DropdownMenuItem(
                                value: country,
                                child: Text(country),
                              );
                            }).toList(),
                        onChanged:
                            (val) => setState(() => selectedCountry = val!),
                      ),
                      SizedBox(height: 24),

                      Text(
                        "📅 Check-in & Check-out Dates",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.indigo,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Check-in
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calendar_today, color: Colors.teal),
                        title: Text(
                          from_date_time != null
                              ? "Check-in: ${from_date_time!.toLocal()}".split(
                                ' ',
                              )[0]
                              : "Select Check-in Date",
                        ),
                        onTap: () => pickDate(isCheckIn: true),
                      ),

                      // Check-out
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calendar_today, color: Colors.teal),
                        title: Text(
                          to_date_time != null
                              ? "Check-out: ${to_date_time!.toLocal()}".split(
                                ' ',
                              )[0]
                              : "Select Check-out Date",
                        ),
                        onTap: () => pickDate(isCheckIn: false),
                      ),

                      if (from_date_time != null && to_date_time != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "🕒 Staying $daysStayed day(s), Total: \$${totalAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      SizedBox(height: 24),

                      // Payment Method
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.payment),
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                        ),
                        value:
                            selectedPaymentMethod.isNotEmpty
                                ? selectedPaymentMethod
                                : null,
                        items: [
                          DropdownMenuItem(
                            value: 'momo_rwanda',
                            child: Text('MTN Mobile Money (Rwanda)'),
                          ),
                          DropdownMenuItem(
                            value: 'flutterwave',
                            child: Text('Flutterwave - Wallet, Card, Bank'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMethod = value!;
                          });
                        },
                        validator:
                            (val) =>
                                val == null ? 'Select a payment method' : null,
                      ),
                      SizedBox(height: 16),

                      if (selectedPaymentMethod == 'momo_rwanda')
                        TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.phone_android),
                            labelText: 'MTN Momo Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return 'Enter Momo Number';
                            return null;
                          },
                          onSaved: (val) => momoNumber = val!,
                        ),

                      SizedBox(height: 24),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              isSending
                                  ? null
                                  : () {
                                    if (_formKey.currentState!.validate()) {
                                      if (from_date_time == null ||
                                          to_date_time == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please select check-in and check-out dates',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      _formKey.currentState!.save();
                                      sendOTP();
                                    }
                                  },
                          icon:
                              isSending
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Icon(Icons.send),
                          label: Text(isSending ? 'Sending...' : 'Send OTP'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.indigo,
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
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
                      child:
                          isVerifying
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
