enum TransactionType {
  rent,
  sell,
}

enum PropertyStatus {
  pending,
  approved,
  rejected,
  sold,
  rented,
}

class PropertyLocation {
  final String address;
  final String city;
  final double? lat;
  final double? lng;

  PropertyLocation({
    required this.address,
    required this.city,
    this.lat,
    this.lng,
  });

  factory PropertyLocation.fromJson(Map<String, dynamic> json) {
    return PropertyLocation(
      address: json['address'],
      city: json['city'],
      lat: json['coordinates']?['lat']?.toDouble(),
      lng: json['coordinates']?['lng']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'coordinates': {
        'lat': lat,
        'lng': lng,
      },
    };
  }
}

class PropertyFeatures {
  final double area;
  final int bedrooms;
  final int bathrooms;

  PropertyFeatures({
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
  });

  factory PropertyFeatures.fromJson(Map<String, dynamic> json) {
    return PropertyFeatures(
      area: json['area']?.toDouble() ?? 0.0,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
    };
  }
}

class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final TransactionType transactionType;
  final String propertyType;
  final PropertyLocation location;
  final PropertyFeatures features;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final PropertyStatus status;
  final DateTime createdAt;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.transactionType,
    required this.propertyType,
    required this.location,
    required this.features,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.createdAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      transactionType: json['transactionType'] == 'rent'
          ? TransactionType.rent
          : TransactionType.sell,
      propertyType: json['propertyType'],
      location: PropertyLocation.fromJson(json['location']),
      features: PropertyFeatures.fromJson(json['features']),
      images: List<String>.from(json['images'] ?? []).map((img) => 'http://192.168.100.223:5000$img').toList(),
      ownerId: json['owner']?['_id'] ?? json['owner'] ?? '',
      ownerName: json['owner']?['name'] ?? '',
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static PropertyStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return PropertyStatus.approved;
      case 'rejected':
        return PropertyStatus.rejected;
      case 'sold':
        return PropertyStatus.sold;
      case 'rented':
        return PropertyStatus.rented;
      default:
        return PropertyStatus.pending;
    }
  }
}
