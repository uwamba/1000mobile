class Apartment {
  final String name;
  final String description;
  final double price;
  final String location;
  final String apartmentType;
  final List<String> imageUrls;  // List of image URLs for apartment images
  final String imageUrl;  // Single image URL for the main image
  final int floor;
  final int numberOfRooms;
  final double area;
  final bool hasParking;
  final bool hasSecurityCamera;

  Apartment({
    required this.name,
    required this.description,
    required this.price,
    required this.location,
    required this.apartmentType,
    required this.imageUrls,  // Initialize imageUrls list
    required this.imageUrl,   // Initialize imageUrl for the main image
    required this.floor,
    required this.numberOfRooms,
    required this.area,
    required this.hasParking,
    required this.hasSecurityCamera,
  });

  // Convert JSON to Apartment object
  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      name: json['name'],
      description: json['description'],
      price: json['price'],
      location: json['location'],
      apartmentType: json['apartmentType'],
      imageUrl: json['imageUrl'],
      imageUrls: List<String>.from(json['imageUrls']),  // Convert to list of images
      floor: json['floor'],
      numberOfRooms: json['numberOfRooms'],
      area: json['area'],
      hasParking: json['hasParking'],
      hasSecurityCamera: json['hasSecurityCamera'],
    );
  }

  // Convert Apartment object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'location': location,
      'apartmentType': apartmentType,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'floor': floor,
      'numberOfRooms': numberOfRooms,
      'area': area,
      'hasParking': hasParking,
      'hasSecurityCamera': hasSecurityCamera,
    };
  }
}
