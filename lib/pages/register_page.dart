import 'package:chatting_app/components/my_button.dart';
import 'package:chatting_app/components/my_textfield.dart';
import 'package:chatting_app/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  final void Function() onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Updated: controllers moved into state so they can be disposed safely.
  final TextEditingController _unameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();

  @override
  void dispose() {
    _unameController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  // Updated: async register flow with await + mounted checks.
  Future<void> register() async {
    final authService = AuthService();

    // trim before comparing (avoids mismatch caused by spaces)
    final pw = _pwController.text.trim();
    final cpw = _confirmPwController.text.trim();

    if (pw != cpw) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Passwords do not match"),
          // added helpful message (more modern UX)
          content: Text("Please make sure both passwords are the same."),
        ),
      );
      return;
    }

    try {
      await authService.signUpWithUserNameEmailPassword(
        _unameController.text.trim(),
        _emailController.text.trim(),
        pw, // use trimmed pw variable
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // Updated: modern layered auth background.
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          // better UX (dismiss keyboard when dragging)
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Updated: visual header section.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Icon(
                        Icons.message_outlined,
                        color: cs.onPrimaryContainer,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Create account",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Join and start chatting in real-time.",
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Updated: grouped form card with modern spacing.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),

                  // removed border (you requested no borders)
                  // border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    MyTextField(
                      hintText: "Username",
                      obscureText: false,
                      controller: _unameController,
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      hintText: "Email",
                      obscureText: false,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      hintText: "Password",
                      obscureText: true,
                      controller: _pwController,
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      hintText: "Confirm Password",
                      obscureText: true,
                      controller: _confirmPwController,
                    ),
                    const SizedBox(height: 20),
                    MyButton(name: "Create Account", onTap: register),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            " Sign in",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
