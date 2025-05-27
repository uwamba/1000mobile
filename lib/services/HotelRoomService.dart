import 'package:visit_1000_hills/models/HotelRoom.dart';

class HotelRoomService {
  static List<HotelRoom> getHotels() {
    return [
      HotelRoom(
        name: 'Kigali Serena Hotel',
        description: 'A luxurious hotel in the heart of Kigali',
        location: 'Kigali, Rwanda',
        price: 120.0,
        roomType: 'Suite',
        imageUrl: 'assets/images/hotels/hotel1.jpg',
        imageUrls: [
          'assets/images/hotels/hotel1.jpg',
          'assets/images/hotels/hotel2.jpg',
          'assets/images/hotels/hotel3.jpg',
        ], // Updated with multiple images
      ),
      HotelRoom(
        name: 'Radisson Blu Hotel',
        description: 'A modern hotel with stunning city views',
        location: 'Kigali, Rwanda',
        price: 150.0,
        roomType: 'Double',
        imageUrl: 'assets/images/hotels/hotel1.jpg',
        imageUrls: [
          'assets/images/hotels/hotel1.jpg',
          'assets/images/hotels/hotel4.jpg',
        ], // Updated with multiple images
      ),
      HotelRoom(
        name: 'Hotel des Mille Collines',
        description: 'A classic hotel with rich history',
        location: 'Kigali, Rwanda',
        price: 100.0,
        roomType: 'Single',
        imageUrl: 'assets/images/hotels/hotel1.jpg',
        imageUrls: [
          'assets/images/hotels/hotel1.jpg',
          'assets/images/hotels/hotel5.jpg',
        ], // Updated with multiple images
      ),
      HotelRoom(
        name: 'Hotel des Mille Collines',
        description: 'A classic hotel with rich history',
        location: 'Kigali, Rwanda',
        price: 100.0,
        roomType: 'Single',
        imageUrl: 'assets/images/hotels/hotel1.jpg',
        imageUrls: [
          'assets/images/hotels/hotel1.jpg',
          'assets/images/hotels/hotel6.jpg',
        ], // Updated with multiple images
      ),
      // Add more hotels as needed
    ];
  }
}
