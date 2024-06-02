import 'package:flutter/material.dart';

class MyAppState extends ChangeNotifier {
  
  var selectionMap = <int, String>{};
  var selection = <String>{};
  void passSelected(fieldId, selected) {
    selectionMap[fieldId] = selected;
    selection = selectionMap.values.toSet();
    debugPrint(selection.join(','));
  }
}
