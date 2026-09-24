import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  static final instance = PermissionService._();

  Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
}
