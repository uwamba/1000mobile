class Apartment {
  final int id;
  final String name;
  final String? houseType;
  final int? numberOfBedroom;
  final int? numberOfBathroom;
  final bool? kitchenInside;
  final bool? kitchenOutside;
  final bool? hasWifi;
  final bool? hasParking;
  final bool? hasSecurity;
  final int? numberOfFloor;
  final String? address;
  final String coordinate;
  final String? annexes;
  final String? description;
  final String? status;
  final bool? swimmingPool;
  final double pricePerNight;
  final double pricePerMonth;
  final List<Photo> photos;
  final String? createdAt;
  final String? updatedAt;
  final DateTime? availableFrom;   // <-- new field
  final DateTime? availableTo;

  Apartment({
    required this.id,
    required this.name,
    required this.houseType,
    required this.numberOfBedroom,
    required this.numberOfBathroom,
    required this.kitchenInside,
    required this.kitchenOutside,
    required this.hasWifi,
    required this.hasParking,
    required this.hasSecurity,
    required this.numberOfFloor,
    required this.address,
    required this.coordinate,
    this.annexes,
    this.description,
    required this.status,
    required this.swimmingPool,
    required this.pricePerNight,
    required this.pricePerMonth,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
    this.availableFrom,
    this.availableTo,// <-- add to constructor
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'],
      name: json['name'],
      houseType: json['house_type'],
      numberOfBedroom: json['number_of_bedroom'],
      numberOfBathroom: json['number_of_bathroom'],
      kitchenInside: json['kitchen_inside'],
      kitchenOutside: json['kitchen_outside'],
      hasWifi: json['has_wifi'],
      hasParking: json['has_parking'],
      hasSecurity: json['has_security'],
      numberOfFloor: json['number_of_floor'],
      address: json['address'],
      coordinate: json['coordinate'],
      annexes: json['annexes'],
      description: json['description'],
      status: json['status'],
      swimmingPool: json['swimming_pool'],
      pricePerNight: double.tryParse(json['price_per_night'].toString()) ?? 0.0,
      pricePerMonth: double.tryParse(json['price_per_month'].toString()) ?? 0.0,

      photos: (json['photos'] as List<dynamic>)
          .map((p) => Photo.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      availableFrom: json['available_from'] != null
          ? DateTime.tryParse(json['available_from'])
          : null,  // <-- parse here safely
      availableTo: json['available_to'] != null
          ? DateTime.tryParse(json['available_to'])
          : null,  // <-- parse here safely
    );
  }
}



class Photo {
  final int id;
  final String name;
  final String url;
  final String? status;
  final String? deletedOn;
  final User? updatedBy;
  final User? deletedBy;

  Photo({
    required this.id,
    required this.name,
    required this.url,
    this.status,
    this.deletedOn,
    this.updatedBy,
    this.deletedBy,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      status: json['status'],
      deletedOn: json['deleted_on'],
      updatedBy:
      json['updated_by'] != null ? User.fromJson(json['updated_by']) : null,
      deletedBy:
      json['deleted_by'] != null ? User.fromJson(json['deleted_by']) : null,
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}


