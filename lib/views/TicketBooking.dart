import 'package:flutter/material.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("From: $from", style: Theme.of(context).textTheme.titleMedium),
                Text("To: $to", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text("Agency: $agency"),
                Text("Price: \$${price.toString()}"),
                Text("Time: $time"),
                Text("Date: ${date.day}/${date.month}/${date.year}"),
                Text("Seat: $seat"),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            amount: price,
                          ),
                        ),
                      );
                    },
                    child: const Text("Proceed to Payment"),
                  ),

                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
