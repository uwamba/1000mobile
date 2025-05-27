import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;

  const PaymentScreen({super.key, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String paymentMethod = "Card";
  final _formKey = GlobalKey<FormState>();

  // Card info
  String? cardNumber, expiryDate, cvv;

  // Mobile money info
  String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Amount to pay: \$${widget.amount}", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),

              // Payment Method
              Row(
                children: [
                  Radio<String>(
                    value: "Card",
                    groupValue: paymentMethod,
                    onChanged: (val) => setState(() => paymentMethod = val!),
                  ),
                  const Text("Card"),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: "MobileMoney",
                    groupValue: paymentMethod,
                    onChanged: (val) => setState(() => paymentMethod = val!),
                  ),
                  const Text("Mobile Money"),
                ],
              ),

              const SizedBox(height: 20),

              // Fields based on selection
              if (paymentMethod == "Card") ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: "Card Number"),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => cardNumber = val,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Expiry Date (MM/YY)"),
                  keyboardType: TextInputType.datetime,
                  onSaved: (val) => expiryDate = val,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "CVV"),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => cvv = val,
                ),
              ] else ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: "Mobile Number"),
                  keyboardType: TextInputType.phone,
                  onSaved: (val) => phoneNumber = val,
                ),
              ],

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Payment Successful")),
                    );
                    Navigator.pop(context); // return to booking screen
                  }
                },
                child: const Text("Pay Now"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
