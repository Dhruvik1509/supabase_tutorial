import 'package:flutter/material.dart';

void showSackBar(BuildContext context,String message){
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}