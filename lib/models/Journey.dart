import 'Bus.dart';

class Journey {
  final String? id;
  final String from;
  final String to;
  final String departure;
  final String returnTime;
  final String busId;
  final String price; // Make nullable
  final Bus? bus;
  final String status;


  Journey({
    this.id,
    required this.from,
    required this.to,
    required this.departure,
    required this.returnTime,
    required this.busId,
    required this.price,
    required this.bus,
    required this.status,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'],
      from: json['from'],
      to: json['to'],
      departure: json['departure'],
      returnTime: json['return'],
      busId: json['bus_id'],
      price: json['price']?.toDouble(), // Safe conversion with null check
      bus: json['bus'] != null ? Bus.fromJson(json['bus']) : null,
      status: json['status'],
    );
  }
}
