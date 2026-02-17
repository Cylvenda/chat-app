import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String name;
  final void Function()? onTap;

  const MyButton({super.key, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Material(
        color: cs.primary, // use primary instead of secondary
        borderRadius: BorderRadius.circular(14), // smoother radius
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: cs.onPrimary.withOpacity(0.1), // soft ripple
          highlightColor: Colors.transparent,
          child: Container(
            width: double.infinity, //  full width button
            padding: const EdgeInsets.symmetric(
              vertical: 18,
            ), // better vertical padding
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  color: cs.onPrimary, // correct contrast color
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // stronger text
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
