import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:homely/extensions/phone_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/friend.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../services/permission_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = false;
  bool _permissionDenied = false;

  Map<String, User> _homelyUsers = {};
  Map<String, FriendStatus> _friendshipStatuses = {};

  final UserService _userService = UserService();
  final PermissionService _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    final hasContactPermission = await _permissionService
        .hasContactsPermission();

    if (!hasContactPermission) {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
      return;
    }

    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.phone},
    );

    final filteredContacts = contacts
        .where(
          (c) =>
              c.phones.isNotEmpty &&
              (c.name?.first ?? '').isNotEmpty &&
              (c.displayName ?? '').isNotEmpty,
        )
        .toList();

    // Cross-reference contacts against Firestore
    await _matchContactsWithHomelyUsers(filteredContacts);

    setState(() {
      _contacts = filteredContacts;
      _isLoading = false;
    });
  }

  Future<void> _matchContactsWithHomelyUsers(List<Contact> contacts) async {
    final Map<String, User> homelyUsers = {};
    final Map<String, FriendStatus> friendshipStatuses = {};

    // Get current user's friends list once
    final friends = await _userService.getFriendsAndPending();

    // Build a map of friendUserId → status for quick lookup
    final Map<String, FriendStatus> friendMap = {
      for (final f in friends) f.friendUserId: f.status,
    };

    // Check each contact against Firestore
    for (final contact in contacts) {
      final normalizedPhone = contact.phones.first.number.normalizePhone();

      final homelyUser = await _userService.findUserByPhone(normalizedPhone);

      if (homelyUser != null) {
        homelyUsers[normalizedPhone] = homelyUser;

        // Check if we already have a friendship with this user
        if (friendMap.containsKey(homelyUser.userId)) {
          friendshipStatuses[homelyUser.userId] = friendMap[homelyUser.userId]!;
        }
      }
    }

    setState(() {
      _homelyUsers = homelyUsers;
      _friendshipStatuses = friendshipStatuses;
    });
  }

  Future<void> _sendFriendRequest(User targetUser) async {
    await _userService.sendFriendRequest(targetUser);
    setState(() {
      _friendshipStatuses[targetUser.userId] = FriendStatus.pending;
    });
  }

  Future<void> _sendSmsInvite(String phoneNumber, String name) async {
    final String message =
        'Hey $name! I\'m using Homely to share my home with friends. '
        'Join me! Download the app: https://homely.app/invite';

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open SMS app')));
      }
    }
  }

  String _getInitials(Contact contact) {
    final String first = contact.name?.first?.isNotEmpty == true
        ? contact.name!.first![0]
        : '';
    final String last = contact.name?.last?.isNotEmpty == true
        ? contact.name!.last![0]
        : '';
    return (first + last).toUpperCase();
  }

  // Returns the correct trailing button based on friendship status
  Widget _buildContactAction(Contact contact) {
    final normalizedPhone = contact.phones.first.number.normalizePhone();
    final homelyUser = _homelyUsers[normalizedPhone];

    // Not on Homely — show Invite
    if (homelyUser == null) {
      return TextButton(
        onPressed: () =>
            _sendSmsInvite(contact.phones.first.number, contact.name!.first!),
        child: const Text('Invite', style: TextStyle(color: Color(0xFF6C63FF))),
      );
    }

    final status = _friendshipStatuses[homelyUser.userId];

    // Already friends
    if (status == FriendStatus.accepted) {
      return TextButton(
        onPressed: null,
        child: const Text('Friends', style: TextStyle(color: Colors.green)),
      );
    }

    // Request already sent
    if (status == FriendStatus.pending) {
      return TextButton(
        onPressed: null,
        child: const Text('Pending', style: TextStyle(color: Colors.orange)),
      );
    }

    // On Homely but not yet friends — show Add Friend
    return TextButton(
      onPressed: () => _sendFriendRequest(homelyUser),
      child: const Text(
        'Add Friend',
        style: TextStyle(color: Color(0xFF6C63FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return _buildPermissionDenied();
    }

    if (_contacts.isEmpty) {
      return const Center(child: Text('No contacts found'));
    }

    return _buildContactsList();
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Contacts Access Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Homely needs access to your contacts to help you invite friends.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadContacts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.separated(
      itemCount: _contacts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final String initials = _getInitials(contact);
        final String displayName = contact.displayName!;
        final String phoneNumber = contact.phones.first.number;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(displayName),
          subtitle: Text(phoneNumber),
          trailing: _buildContactAction(contact),
        );
      },
    );
  }
}
