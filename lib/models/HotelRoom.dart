class HotelRoom {
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String location;
  final String roomType;
  final List<String> imageUrls; // List of image URLs

  HotelRoom({
    required this.name,
    required this.description,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.roomType,
    required this.imageUrls, // Initialize imageUrls list
  });

  // Convert JSON to HotelRoom object
  factory HotelRoom.fromJson(Map<String, dynamic> json) {
    return HotelRoom(
      name: json['name'],
      description: json['description'],
      price: json['price'],
      location: json['location'],
      roomType: json['roomType'],
      imageUrl: json['imageUrl'],
      imageUrls: List<String>.from(json['imageUrls']), // Convert to list of images
    );
  }

  // Convert HotelRoom object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location':location,
      'roomType':roomType,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}
