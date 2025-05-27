import 'Journey.dart';

class JourneyResponse {
  final int? currentPage;
  final int? lastPage;
  final List<Journey> data;

  JourneyResponse({this.currentPage, this.lastPage, required this.data});

  factory JourneyResponse.fromJson(Map<String, dynamic> json) => JourneyResponse(
    currentPage: json['current_page'],
    lastPage: json['last_page'],
    data: List<Journey>.from((json['data'] ?? []).map((j) => Journey.fromJson(j))),
  );
}
