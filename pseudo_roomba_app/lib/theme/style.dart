import 'package:flutter/material.dart';

abstract class AppTheme {
  static const Color backgroundColor = Color.fromARGB(255, 216, 216, 216);
  static const Color primaryBlack = Color.fromARGB(255, 54, 54, 54);
  static const Color primaryWhite = Color.fromARGB(255, 255, 255, 255);

  static const TextStyle Title = TextStyle(
      fontFamily: 'Helvitica',
      color: Colors.black,
      fontSize: 30,
      height: 0.5,
      fontWeight: FontWeight.w200);

  static const TextStyle Body = TextStyle(
      fontFamily: 'Helvitica',
      color: Colors.white,
      fontSize: 10,
      height: 0.5,
      fontWeight: FontWeight.w100);

  static const TextStyle Footer = TextStyle(
      fontFamily: 'Helvitica',
      color: Colors.white,
      fontSize: 5,
      height: 0.5,
      fontWeight: FontWeight.w100);
}
