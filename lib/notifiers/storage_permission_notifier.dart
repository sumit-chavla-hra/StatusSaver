import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:status_saver/common.dart';
import 'package:status_saver/services/show_without_ui_block_message.dart';

class StoragePermissionNotifier extends StateNotifier<PermissionStatus?> {

  Permission? _storagePermission;
  bool _tempFirstTime = true;

  StoragePermissionNotifier(): super(null);

  void initialize() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    _storagePermission = androidInfo.version.sdkInt >= 31 
    ? Permission.manageExternalStorage
    : Permission.storage;
    state = await _storagePermission?.request();
  }

  PermissionStatus? get status => state;

  void requestAndHandle(BuildContext context) {
    if(_storagePermission == null) return;

    _storagePermission!.request()
    .then((status) async {
      switch(status) {
        case PermissionStatus.granted:
          state = PermissionStatus.granted;
          return;
        case PermissionStatus.denied:
          return;
        case PermissionStatus.permanentlyDenied: 
        case PermissionStatus.restricted:
        case PermissionStatus.limited: // do not have idea about limited
          if(_tempFirstTime) {
            _tempFirstTime = false;
            return;
          }
          openAppSettings()
          .then((value) {
            if(value) {
              showMessageWithoutUiBlock(message: AppLocalizations.of(context)?.allowStoragePermission ?? "Allow storage permission for Status Saver",toastLength: Toast.LENGTH_LONG); // FIXME: dynamic app name
            } else {
              showMessageWithoutUiBlock(message: AppLocalizations.of(context)?.couldNotOpenAppSettings ?? "Could not open app settings for storage permission.");
            }
          });
          return;
      }
    });
  }
}