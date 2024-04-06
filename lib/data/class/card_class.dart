// ignore_for_file: public_member_api_docs, sort_constructors_first


import 'package:flutter/material.dart';

class CardClass {
  final String name;
  final String description;
  final Widget child;
  final Function() onPressed;
  final Color color;
  final Color colorText;
  CardClass({
    required this.name,
    required this.description,
    required this.child,
    required this.onPressed,
    required this.color,
    required this.colorText,
  });
  
}
