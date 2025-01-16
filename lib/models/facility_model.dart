class Facility {
  final String name;
  final String description;
  final String location;
  final String imagePath;

  Facility({
    required this.name,
    required this.description,
    required this.location,
    required this.imagePath,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      name: json['name'],
      description: json['description'],
      location: json['location'],
      imagePath: json['image'],
    );
  }
}
