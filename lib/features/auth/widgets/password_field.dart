import 'package:flutter/material.dart';

/// Material 3 password field with visibility toggle
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const PasswordField({
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.enabled = true,
    this.validator,
    this.onChanged,
    super.key,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: widget.enabled
              ? () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                }
              : null,
          tooltip: _obscureText ? 'Show password' : 'Hide password',
        ),
      ),
      obscureText: _obscureText,
      enabled: widget.enabled,
      validator: widget.validator,
      onChanged: widget.onChanged,
    );
  }
}
