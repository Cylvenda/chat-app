import 'package:chatting_app/pages/login_page.dart';
import 'package:chatting_app/pages/register_page.dart';
import 'package:flutter/material.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // to initial show the login page
  bool showLoginPage = true;

  // toggle between login and register page
  void toggleAuthPages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(onTap: toggleAuthPages);
    } else {
      return RegisterPage(onTap: toggleAuthPages);
    }
  }
}
