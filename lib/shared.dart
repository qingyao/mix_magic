import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class Ingredient {
  final String name;
  final double? amount;
  final String unit;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    required,
  });
}

class DatabaseProvider with ChangeNotifier {
  final Database database;

  DatabaseProvider(this.database);

  // Additional methods to interact with the database can be added here.
}
