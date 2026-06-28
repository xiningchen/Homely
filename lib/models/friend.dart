import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendStatus { pending, accepted, declined }

class Friend {
  final String friendUserId;
  final String friendFirstName;
  final String friendLastName;
  final String friendPhone;
  final FriendStatus status;
  final String requestedBy;
  final DateTime createdAt;

  Friend({
    required this.friendUserId,
    required this.friendFirstName,
    required this.friendLastName,
    required this.friendPhone,
    required this.status,
    required this.requestedBy,
    required this.createdAt,
  });

  String get fullName => '$friendFirstName $friendLastName';

  static String statusToString(FriendStatus status) {
    switch (status) {
      case FriendStatus.pending:
        return 'pending';
      case FriendStatus.accepted:
        return 'accepted';
      case FriendStatus.declined:
        return 'declined';
    }
  }

  static FriendStatus statusFromString(String status) {
    switch (status) {
      case 'accepted':
        return FriendStatus.accepted;
      case 'declined':
        return FriendStatus.declined;
      default:
        return FriendStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'friendFirstName': friendFirstName,
      'friendLastName': friendLastName,
      'friendPhone': friendPhone,
      'status': statusToString(status),
      'requestedBy': requestedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Friend.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      friendUserId: doc.id,
      friendFirstName: data['friendFirstName'] ?? '',
      friendLastName: data['friendLastName'] ?? '',
      friendPhone: data['friendPhone'] ?? '',
      status: statusFromString(data['status'] ?? 'pending'),
      requestedBy: data['requestedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
