import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:visit_1000_hills/views/ApartmentListView.dart';

import '../models/Apartment.dart';




class BookApartmentForm extends StatefulWidget {
  final  Apartment apartment;

  const BookApartmentForm({required this.apartment, Key? key}) : super(key: key);

  @override
  _BookApartmentFormState createState() => _BookApartmentFormState();
}

class _BookApartmentFormState extends State<BookApartmentForm> {
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
    return (daysStayed > 0 ? daysStayed : 0) *  100;
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
          if (to_date_time != null && from_date_time!.isAfter(to_date_time!)) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP')),
      );
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
        'journey': widget.apartment.name,
        'object_type': 'room',
        'object_id': widget.apartment.name,
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
            content: Text("Your booking was successful! A payment link has been sent to your email."),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification or booking failed')),
      );
    } finally {
      setState(() => isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: step == "form"
            ? Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book Room at ${widget.apartment.name}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => fullName = val!,
              ),

              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => email = val!,
              ),

              TextFormField(
                decoration: InputDecoration(labelText: 'Address'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => address = val!,
              ),

              TextFormField(
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => phoneNumber = val!,
              ),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Country'),
                value: selectedCountry,
                items: ['Rwanda', 'Kenya', 'Uganda'].map((country) {
                  return DropdownMenuItem(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedCountry = val!),
              ),

              SizedBox(height: 16),
              Text("Check-in & Check-out Dates", style: TextStyle(fontWeight: FontWeight.bold)),

              ListTile(
                title: Text(from_date_time != null
                    ? "Check-in: ${from_date_time!.toLocal()}".split(' ')[0]
                    : "Select Check-in Date"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => pickDate(isCheckIn: true),
              ),

              ListTile(
                title: Text(to_date_time != null
                    ? "Check-out: ${to_date_time!.toLocal()}".split(' ')[0]
                    : "Select Check-out Date"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => pickDate(isCheckIn: false),
              ),

              if (from_date_time != null && to_date_time != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("Staying $daysStayed day(s), Total: \$${totalAmount.toStringAsFixed(2)}"),
                ),

              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Payment Method'),
                value: selectedPaymentMethod.isNotEmpty ? selectedPaymentMethod : null,
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
                validator: (val) => val == null ? 'Select a payment method' : null,
              ),

              if (selectedPaymentMethod == 'momo_rwanda')
                TextFormField(
                  decoration: InputDecoration(labelText: 'MTN Momo Number'),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'Enter Momo Number' : null,
                  onSaved: (val) => momoNumber = val!,
                ),

              SizedBox(height: 16),

              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    if (from_date_time == null || to_date_time == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select check-in and check-out dates')),
                      );
                      return;
                    }
                    _formKey.currentState!.save();
                    sendOTP();
                  }
                },
                child: isSending ? CircularProgressIndicator() : Text('Send OTP'),
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
              child: isVerifying ? CircularProgressIndicator() : Text('Verify & Confirm Booking'),
            ),
          ],
        )
            : Center(child: Text("Booking completed successfully!")),
      ),
    );
  }
}
