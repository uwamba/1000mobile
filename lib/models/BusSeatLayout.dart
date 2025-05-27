class BusSeatLayout {
  final int id, row, column, seatRow, seatColumn;
  final String name;
  final List<int> exclude;

  BusSeatLayout({
    required this.id,
    required this.name,
    required this.row,
    required this.column,
    required this.seatRow,
    required this.seatColumn,
    required this.exclude,
  });

  factory BusSeatLayout.fromJson(Map<String, dynamic> json) => BusSeatLayout(
    id: json['id'],
    name: json['name'],
    row: json['row'],
    column: json['column'],
    seatRow: json['seat_row'],
    seatColumn: json['seat_column'],
    exclude: List<int>.from(json['exclude'] ?? []),
  );
}
