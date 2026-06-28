import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as user_model;
import '../models/friend.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser!.uid;

  // Save user profile to Firestore after signup
  Future<void> createUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    final user = user_model.User(
      userId: _currentUserId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(_currentUserId).set(user.toMap());
  }

  // Get a user profile by userId
  Future<user_model.User?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) return null;
    return user_model.User.fromDocument(doc);
  }

  // Get current user's profile
  Future<user_model.User?> getCurrentUserProfile() async {
    return getUserProfile(_currentUserId);
  }

  // Find a user by phone number
  // Used to check if a contact is already on Homely
  Future<user_model.User?> findUserByPhone(String phone) async {
    final query = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return user_model.User.fromDocument(query.docs.first);
  }

  // ─── Friend Requests ────────────────────────────────────────

  // Send a friend request to another Homely user
  Future<void> sendFriendRequest(user_model.User targetUser) async {
    final currentUser = await getCurrentUserProfile();
    if (currentUser == null) return;

    final batch = _firestore.batch();

    // Write to current user's friends subcollection
    final myFriendRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .doc(targetUser.userId);

    // Write to target user's friends subcollection
    final theirFriendRef = _firestore
        .collection('users')
        .doc(targetUser.userId)
        .collection('friends')
        .doc(_currentUserId);

    final now = DateTime.now();

    // My side — I see them as pending
    batch.set(
      myFriendRef,
      Friend(
        friendUserId: targetUser.userId,
        friendFirstName: targetUser.firstName,
        friendLastName: targetUser.lastName,
        friendPhone: targetUser.phone,
        status: FriendStatus.pending,
        requestedBy: _currentUserId,
        createdAt: now,
      ).toMap(),
    );

    // Their side — they see me as pending
    batch.set(
      theirFriendRef,
      Friend(
        friendUserId: _currentUserId,
        friendFirstName: currentUser.firstName,
        friendLastName: currentUser.lastName,
        friendPhone: currentUser.phone,
        status: FriendStatus.pending,
        requestedBy: _currentUserId,
        createdAt: now,
      ).toMap(),
    );

    // Commit both writes atomically
    await batch.commit();
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(String fromUserId) async {
    final batch = _firestore.batch();

    // Update both sides to accepted
    final myFriendRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .doc(fromUserId);

    final theirFriendRef = _firestore
        .collection('users')
        .doc(fromUserId)
        .collection('friends')
        .doc(_currentUserId);

    batch.update(myFriendRef, {'status': 'accepted'});
    batch.update(theirFriendRef, {'status': 'accepted'});

    await batch.commit();
  }

  // Decline a friend request
  Future<void> declineFriendRequest(String fromUserId) async {
    final batch = _firestore.batch();

    final myFriendRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .doc(fromUserId);

    final theirFriendRef = _firestore
        .collection('users')
        .doc(fromUserId)
        .collection('friends')
        .doc(_currentUserId);

    batch.update(myFriendRef, {'status': 'declined'});
    batch.update(theirFriendRef, {'status': 'declined'});

    await batch.commit();
  }

  // Get all accepted friends
  Stream<List<Friend>> getFriendsStream() {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Friend.fromDocument(doc)).toList(),
        );
  }

  // Get all pending friend requests sent TO me
  Stream<List<Friend>> getPendingRequestsStream() {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'pending')
        .where('requestedBy', isNotEqualTo: _currentUserId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Friend.fromDocument(doc)).toList(),
        );
  }

  // Get all friends regardless of status (for cross-referencing)
  Future<List<Friend>> getFriendsAndPending() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .get();

    return snapshot.docs.map((doc) => Friend.fromDocument(doc)).toList();
  }
}
