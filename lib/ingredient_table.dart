import 'helper.dart';
import 'package:flutter/material.dart';
import 'shared.dart';
import 'package:provider/provider.dart';

class EditIngredientTable extends StatefulWidget {
  final int recipeId;
  final List<Ingredient> ingredientDetail;

  const EditIngredientTable({
    super.key,
    required this.recipeId,
    required this.ingredientDetail,
  });

  @override
  State<EditIngredientTable> createState() => _EditIngredientTableState();
}

class _EditIngredientTableState extends State<EditIngredientTable> {
  late List<List<TextEditingController>> ingredientController;
  // late List<bool> selected;

  @override
  void initState() {
    super.initState();
    ingredientController = widget.ingredientDetail.map((i) {
      return [
        TextEditingController(text: i.name),
        TextEditingController(text: "${doubleToString(i.amount)} ${i.unit}")
      ];
    }).toList();
    // selected=List<bool>.generate(widget.ingredientDetail.length,
    // (int index) => false);
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseProvider>(context).database;

    void DbUpdateIngredientName(int idx) {
      var oldName = widget.ingredientDetail[idx].name;
      var data = {'ingredient_name': ingredientController[idx][0].text};
      db.update('recipe', data,
          where: 'ingredient_name=?', whereArgs: [oldName]);
      db.update('ingredient', data,
          where: 'ingredient_name=?', whereArgs: [oldName]);
      print('Db updated ingredient name');
    }

    void DbUpdateIngredientAmount(int idx, int recipeId) async {
      var newAmount = ingredientController[idx][1].text.trim();
      var ingredientName = ingredientController[idx][0].text;

      double newNumber;
      String newUnit;

      if (newAmount.split(' ').length == 2) {
        try {
          newNumber = double.parse(newAmount.split(' ')[0]);
        } catch (_) {
          // implement error info to user if the format is incorrect
          print('Could not parse number');
          return;
        }
      } else {
        // implement error info to user if the format is incorrect
        print("It's not 2 words");
        return;
      }
      try {
        newUnit = newAmount.split(' ')[1];
      } catch (_) {
        print('Couldn not parse unit');
        return;
      }
      // have to use raw update because AND in WHERE clause
      await db.rawUpdate(
          "UPDATE recipe SET ingredient_amount = ?, ingredient_unit = ? WHERE recipe_id = ? AND ingredient_name = ?",
          [newNumber, newUnit, recipeId, ingredientName]);

      print('Db updated ingredient amount');
    }

    return SingleChildScrollView(
        child: DataTable(
            dataRowMinHeight: 30,
            dataRowMaxHeight: 40,
            headingRowHeight: 40,
            columns: ["Ingredient", "Amount"]
                .map((i) => DataColumn(
                      label: Expanded(
                          child: Text(i,
                              style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer))),
                    ))
                .toList(),
            rows: ingredientController.asMap().entries.map((entry) {
              int idx = entry.key;
              List<TextEditingController> i = entry.value;
              return DataRow(
                // selected: selected[idx],
                // onSelectChanged: (bool? value) {
                //   setState(() {
                //     selected[idx] = value!;
                //     // print(Theme.of(context).dataTableTheme.dataTextStyle);
                //   });
                // },
                cells: [
                  DataCell(TextField(
                      controller: i[0],
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                      onEditingComplete: () {
                        DbUpdateIngredientName(idx);
                        FocusScope.of(context).unfocus();
                      },
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer))),
                  DataCell(TextField(
                    controller: i[1],
                    decoration: const InputDecoration(border: InputBorder.none),
                    onEditingComplete: () {
                      DbUpdateIngredientAmount(idx, widget.recipeId);
                      FocusScope.of(context).unfocus();
                    },
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  )),
                ],
              );
            }).toList()));
  }
}

class IngredientTable extends StatefulWidget {
  final List<Ingredient> ingredientDetail;
  final int recipeId;

  const IngredientTable({
    super.key,
    required this.recipeId,
    required this.ingredientDetail,
  });

  @override
  State<IngredientTable> createState() => _IngredientTableState();
}

class _IngredientTableState extends State<IngredientTable> {
  late List<bool> selected;
  @override
  void initState() {
    super.initState();
    selected = List<bool>.generate(
        widget.ingredientDetail.length, (int index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: DataTable(
            dataRowMinHeight: 30,
            dataRowMaxHeight: 40,
            headingRowHeight: 40,
            columns: ["Ingredient", "Amount"]
                .map((i) => DataColumn(
                      label: Expanded(
                          child: Text(i,
                              style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer))),
                    ))
                .toList(),
            rows: widget.ingredientDetail.asMap().entries.map((entry) {
              int idx = entry.key;
              Ingredient i = entry.value;
              return DataRow(
                selected: selected[idx],
                onSelectChanged: (bool? value) {
                  setState(() {
                    selected[idx] = value!;
                    // print(Theme.of(context).dataTableTheme.dataTextStyle);
                  });
                },
                cells: [
                  DataCell(Text(i.name,
                      style: TextStyle(
                          decoration: selected[idx] == true
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer))),
                  DataCell(Text(
                    "${doubleToString(i.amount)} ${i.unit}",
                    style: TextStyle(
                        decoration: selected[idx] == true
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  )),
                ],
              );
            }).toList()));
  }
}
