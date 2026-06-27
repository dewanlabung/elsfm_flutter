import 'package:flutter/material.dart';

/// Material 3 email field with real-time validation
class EmailField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final void Function(String)? onChanged;

  const EmailField({
    required this.controller,
    this.label = 'Email',
    this.hint,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  String? _errorMessage;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email address';
    }

    return null;
  }

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
        prefixIcon: const Icon(Icons.email),
        errorText: _errorMessage,
      ),
      keyboardType: TextInputType.emailAddress,
      enabled: widget.enabled,
      validator: _validateEmail,
      onChanged: (value) {
        setState(() {
          _errorMessage = _validateEmail(value);
        });
        widget.onChanged?.call(value);
      },
    );
  }
}
