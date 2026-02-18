import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final FocusNode? focusNode;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,

        // modern clean input decoration
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant, // softer hint color
          ),

          // removed filled background
          filled: false,

          // removed box borders
          border: InputBorder.none,

          // bottom border when not focused
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: cs.outlineVariant, width: 1),
          ),

          // bottom border when focused
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: cs.primary,
              width: 2, // thicker when active
            ),
          ),

          // better vertical spacing
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
