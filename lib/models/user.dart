import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime createdAt;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  // "Serialization to save Model to Firestore document"
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // "DESerialization to get Model from a Firestore document"
  factory User.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      userId: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
