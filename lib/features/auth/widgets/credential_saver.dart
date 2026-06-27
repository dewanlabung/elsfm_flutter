import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _rememberMeKey = 'remember_me';
const _emailKey = 'saved_email';

/// Manages saving and loading credentials
class CredentialSaver {
  final FlutterSecureStorage _storage;

  CredentialSaver(this._storage);

  /// Save email for "Remember me"
  Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _rememberMeKey, value: 'true');
  }

  /// Get saved email if "Remember me" was enabled
  Future<String?> getSavedEmail() async {
    final rememberMe = await _storage.read(key: _rememberMeKey);
    if (rememberMe != 'true') return null;

    return await _storage.read(key: _emailKey);
  }

  /// Check if "Remember me" is enabled
  Future<bool> isRememberMeEnabled() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }

  /// Clear saved credentials
  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _rememberMeKey);
  }
}

/// "Remember me" checkbox widget
class RememberMeCheckbox extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const RememberMeCheckbox({
    this.initialValue = false,
    required this.onChanged,
    super.key,
  });

  @override
  State<RememberMeCheckbox> createState() => _RememberMeCheckboxState();
}

class _RememberMeCheckboxState extends State<RememberMeCheckbox> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _isChecked,
          onChanged: (value) {
            setState(() {
              _isChecked = value ?? false;
            });
            widget.onChanged(_isChecked);
          },
        ),
        const SizedBox(width: 8),
        const Text('Remember me'),
      ],
    );
  }
}
