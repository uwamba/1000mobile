import 'package:flutter/material.dart';
import 'dart:ui';
import 'PaymentScreen.dart';

class BookingScreen extends StatelessWidget {
  final String from;
  final String to;
  final String time;
  final DateTime date;
  final String agency;
  final int price;
  final String seat;

  const BookingScreen({
    super.key,
    required this.from,
    required this.to,
    required this.time,
    required this.date,
    required this.agency,
    required this.price,
    required this.seat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Booking")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          margin: const EdgeInsets.all(8),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Info
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.indigo, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "From: $from",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.indigo, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "To: $to",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),

                    // Trip Details
                    buildDetailRow(Icons.business, "Agency", agency),
                    buildDetailRow(Icons.attach_money, "Price", "\$${price.toString()}"),
                    buildDetailRow(Icons.access_time, "Time", time),
                    buildDetailRow(Icons.calendar_today, "Date", "${date.day}/${date.month}/${date.year}"),
                    buildDetailRow(Icons.event_seat, "Seat", seat),

                    const SizedBox(height: 20),

                    // Book Button
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment, size: 20),
                        label: const Text("Proceed to Payment"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(amount: price),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget to display detail rows with icons
Widget buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[800]),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}
