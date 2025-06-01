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
  String selectedCountry = 'Rwanda';
  String selectedPaymentMethod = '';
  String momoNumber = '';
  String step = "form";
  bool isSending = false;
  bool isVerifying = false;

  DateTime? fromDate;
  DateTime? toDate;

  int get daysStayed => fromDate != null && toDate != null ? toDate!.difference(fromDate!).inDays : 0;
  double get totalAmount => (daysStayed > 0 ? daysStayed : 0) * 100;

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
        'journey': widget.apartment.name,
        'object_type': 'apartment',
        'object_id': widget.apartment.id,
        'from_date_time': fromDate!.toIso8601String(),
        'to_date_time': toDate!.toIso8601String(),
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
        builder: (context) => AlertDialog(
          title: Text("Booking Successful"),
          content: Text("Payment link sent to your email."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed')));
    } finally {
      setState(() => isVerifying = false);
    }
  }

  Widget buildTextField(
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        required FormFieldSetter<String> onSaved,
      }) {
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

  Widget buildForm() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Book ${widget.apartment.name}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),

              buildTextField('Full Name', Icons.person, onSaved: (val) => fullName = val!),
              buildTextField('Email', Icons.email, keyboardType: TextInputType.emailAddress, onSaved: (val) => email = val!),
              buildTextField('Address', Icons.location_on, onSaved: (val) => address = val!),
              buildTextField('Phone Number', Icons.phone, keyboardType: TextInputType.phone, onSaved: (val) => phoneNumber = val!),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(prefixIcon: Icon(Icons.flag), labelText: 'Country'),
                value: selectedCountry,
                items: ['Rwanda', 'Kenya', 'Uganda'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => selectedCountry = val!),
              ),

              buildDatePickerTile('Check-in', fromDate, () => pickDate(isCheckIn: true)),
              buildDatePickerTile('Check-out', toDate, () => pickDate(isCheckIn: false)),

              if (fromDate != null && toDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("Total: $daysStayed nights | \$${totalAmount.toStringAsFixed(2)}",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(prefixIcon: Icon(Icons.payment), labelText: 'Payment Method'),
                value: selectedPaymentMethod.isEmpty ? null : selectedPaymentMethod,
                items: [
                  DropdownMenuItem(value: 'momo_rwanda', child: Text('MTN Momo (Rwanda)')),
                  DropdownMenuItem(value: 'flutterwave', child: Text('Flutterwave - Wallet/Card/Bank')),
                ],
                onChanged: (value) => setState(() => selectedPaymentMethod = value ?? ''),
                validator: (val) => val == null || val.isEmpty ? 'Select payment method' : null,
              ),

              if (selectedPaymentMethod == 'momo_rwanda')
                buildTextField('Momo Number', Icons.phone_android,
                    keyboardType: TextInputType.phone, onSaved: (val) => momoNumber = val!),

              SizedBox(height: 20),

              ElevatedButton.icon(
                icon: isSending
                    ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.send),
                label: Text('Send OTP'),
                onPressed: isSending
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    if (fromDate == null || toDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select both dates')));
                      return;
                    }
                    _formKey.currentState!.save();
                    sendOTP();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOTPForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Enter OTP sent to $email', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(prefixIcon: Icon(Icons.security), labelText: 'OTP'),
              onChanged: (val) => otp = val,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: isVerifying
                  ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.check_circle),
              label: Text('Verify & Confirm'),
              onPressed: isVerifying ? null : verifyOTPAndBook,
            ),
          ],
        ),
      ),
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
          child: step == "form"
              ? buildForm()
              : step == "otp"
              ? buildOTPForm()
              : Center(child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text("Booking completed successfully!", style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
          )),
        ),
      ),
    );
  }
}
