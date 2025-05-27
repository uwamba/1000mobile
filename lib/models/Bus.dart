import 'Agency.dart';
import 'BusSeatLayout.dart';

class Bus {
  final String id;
  final String name;
  final Agency agency;
  final BusSeatLayout layout;

  Bus({required this.id, required this.name, required this.agency, required this.layout});

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
    id: json['id'].toString(),
    name: json['name'],
    agency: Agency.fromJson(json['agency']),
    layout: BusSeatLayout.fromJson(json['layout']),
  );
}