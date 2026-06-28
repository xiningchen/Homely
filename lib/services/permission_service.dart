import 'package:flutter_contacts/flutter_contacts.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // ─── Contacts ───────────────────────────────────────────────
  Future<bool> hasContactsPermission() async {
    final existing = await FlutterContacts.permissions.check(
      PermissionType.read,
    );

    if (_isGranted(existing)) return true;

    final requested = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    return _isGranted(requested);
  }

  // ─── Camera (future) ────────────────────────────────────────

  // Future<bool> requestCameraPermission() async {
  //   final status = await Permission.camera.request();
  //   return status.isGranted;
  // }

  // ─── Photo Album (future) ───────────────────────────────────

  // Future<bool> requestPhotoAlbumPermission() async {
  //   final status = await Permission.photos.request();
  //   return status.isGranted;
  // }

  // ─── Private Helpers ────────────────────────────────────────

  bool _isGranted(PermissionStatus status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }
}
