import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/Apartment.dart';

class BookApartmentForm extends StatefulWidget {
  final Apartment apartment;

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
  String selectedCountry = '';
  String selectedPaymentMethod = '';
  String momoNumber = '';
  String selectedPricingMethod = 'daily';
  String extraNote = '';
  String step = "form";
  bool isSending = false;
  bool isVerifying = false;

  DateTime? fromDate;
  DateTime? toDate;

  int getDaysBetween() {
    if (fromDate == null || toDate == null) return 0;
    return toDate!.difference(fromDate!).inDays;
  }

  double get totalAmount {
    final days = getDaysBetween();
    if (selectedPricingMethod == 'monthly') {
      if (days < 30) return 0;
      return (days / 30).ceil() * widget.apartment.pricePerMonth;
    } else {
      return days * widget.apartment.pricePerNight;
    }
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
          fromDate = picked;
          if (toDate != null && fromDate!.isAfter(toDate!)) {
            toDate = null;
          }
        } else {
          toDate = picked;
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
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending OTP')));
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
        'object_type': 'apartment',
        'object_id': widget.apartment.id,
        'from_date_time': fromDate!.toIso8601String(),
        'to_date_time': toDate!.toIso8601String(),
        'pricing_method': selectedPricingMethod,
        'booking_status': 'pending',
        'amount_to_pay': totalAmount,
        'payment_method': selectedPaymentMethod,
        'momo_number': momoNumber,
        'country': selectedCountry,
        'extra_note': extraNote
      };

      final bookingRes = await http.post(
        Uri.parse('$apiUrl/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingData),
      );

      if (bookingRes.statusCode != 201) throw Exception("Booking failed");

      setState(() => step = "success");
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed')));
    } finally {
      setState(() => isVerifying = false);
    }
  }

  Widget buildTextField(String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, required FormFieldSetter<String> onSaved}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget buildDatePickerTile(String label, DateTime? date, VoidCallback onTap) {
    return ListTile(
      leading: Icon(Icons.calendar_today),
      title: Text(date != null ? "$label: ${date.toLocal()}".split(' ')[0] : "Select $label Date"),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Apartment')),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: SingleChildScrollView(
          key: ValueKey(step),
          padding: EdgeInsets.all(16),
          child: step == "form"
              ? Form(
            key: _formKey,
            child: Column(
              children: [
                buildTextField('Full Name', Icons.person, onSaved: (val) => fullName = val!),
                buildTextField('Country', Icons.flag, onSaved: (val) => selectedCountry = val!),
                buildTextField('Email', Icons.email, keyboardType: TextInputType.emailAddress, onSaved: (val) => email = val!),
                buildTextField('Phone Number', Icons.phone, keyboardType: TextInputType.phone, onSaved: (val) => phoneNumber = val!),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(prefixIcon: Icon(Icons.money), labelText: 'Pricing Method'),
                  value: selectedPricingMethod,
                  items: ['daily', 'monthly']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => selectedPricingMethod = val!),
                ),

                buildDatePickerTile('Check-in', fromDate, () => pickDate(isCheckIn: true)),
                buildDatePickerTile('Check-out', toDate, () => pickDate(isCheckIn: false)),

                if (fromDate != null && toDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text("Total: \$${totalAmount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(prefixIcon: Icon(Icons.payment), labelText: 'Payment Method'),
                  value: selectedPaymentMethod.isEmpty ? null : selectedPaymentMethod,
                  items: [
                    DropdownMenuItem(value: 'momo_rwanda', child: Text('MTN Momo (Rwanda)')),
                    DropdownMenuItem(value: 'flutterwave', child: Text('Flutterwave')),
                  ],
                  onChanged: (val) => setState(() => selectedPaymentMethod = val!),
                ),

                if (selectedPaymentMethod == 'momo_rwanda')
                  buildTextField('MoMo Number', Icons.phone_android,
                      keyboardType: TextInputType.phone, onSaved: (val) => momoNumber = val!),

                buildTextField('Extra Note', Icons.note, onSaved: (val) => extraNote = val ?? ''),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (fromDate == null || toDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select both dates.")));
                        return;
                      }
                      final days = getDaysBetween();
                      if (selectedPricingMethod == "monthly" && days < 30) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Minimum stay is 30 days for monthly pricing.")));
                        return;
                      }
                      _formKey.currentState!.save();
                      sendOTP();
                    }
                  },
                  child: isSending ? CircularProgressIndicator() : Text('Send OTP'),
                )
              ],
            ),
          )
              : step == "otp"
              ? Column(
            children: [
              Text("Enter OTP sent to $email", style: TextStyle(fontSize: 18)),
              SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(prefixIcon: Icon(Icons.security), labelText: 'OTP'),
                onChanged: (val) => otp = val,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isVerifying ? null : verifyOTPAndBook,
                child: isVerifying ? CircularProgressIndicator() : Text('Verify & Book'),
              )
            ],
          )
              : Center(
            child: Text("Booking successful!", style: TextStyle(fontSize: 20, color: Colors.green)),
          ),
        ),
      ),
    );
  }
}