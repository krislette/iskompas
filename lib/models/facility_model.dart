// Represents a facility
class Facility {
  final String name;
  final String description;
  final String location;
  final String imagePath;

  // Constructor requiring all fields to be provided
  Facility({
    required this.name,
    required this.description,
    required this.location,
    required this.imagePath,
  });

  // Creates a Facility instance from a JSON map
  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      name: json['name'],
      description: json['description'],
      location: json['location'],
      imagePath: json['image'],
    );
  }
}
