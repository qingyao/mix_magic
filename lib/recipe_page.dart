import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'my_app_state.dart';
import 'helper.dart';
import 'shared.dart';

class RecipePage extends StatefulWidget {
  int recipeId;
  String recipeName;
  List<Ingredient> ingredientDetail;
  final String stepsDetail;
  List<List<TextEditingController>> _controllers = [];

  RecipePage(
      {super.key,
      required this.recipeId,
      required this.recipeName,
      required this.ingredientDetail,
      required this.stepsDetail});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final LineSplitter ls = const LineSplitter();

  @override
  void initState() {
    super.initState();
    widget._controllers = widget.ingredientDetail.map((i) {
      return [
        TextEditingController(text: i.name),
        TextEditingController(text: "${doubleToString(i.amount)} ${i.unit}")
      ];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    var ingredientList = widget.ingredientDetail.map((i) {
      return i.name.toLowerCase().split(' ');
    });
    var flatIngredientList = ingredientList.expand((i) => i).toSet();

    return PopScope(
      canPop: false, // prevents swipeleft as back
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, 'been to recipe');
              },
            ),
            title: Container(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Recipe Detail', //'Tom ka gai',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
          ),
          body: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(widget.recipeName,
                          textScaler: const TextScaler.linear(1.2)),
                    ),
                    Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: IngredientTable(
                                  recipeId: widget.recipeId,
                                  selected: List<bool>.generate(
                                      widget.ingredientDetail.length,
                                      (int index) => false),
                                  ingredientDetail:widget.ingredientDetail,
                                  ingredientController: widget._controllers),
                            ),
                            // Expanded(
                            //     flex: 2,
                            //     child: Column(
                            //       mainAxisSize: MainAxisSize.min,
                            //       children: [
                            //       Expanded(child:(FittedBox(child:FlutterLogo()))),
                            //       Text("30min")]
                            //       ),
                            //   ),
                          ],
                        )),
                    Expanded(
                      flex: 2,
                      child: ListView(
                          padding: const EdgeInsets.all(15),
                          children: ls
                              .convert(widget.stepsDetail)
                              .map((i) => translateStepsToRichText(
                                      i, flatIngredientList, context)
                                  // Text(i,textAlign: TextAlign.left,)
                                  )
                              .toList()),
                    )
                  ],
                ),
              ))),
    );
  }
}

class IngredientTable extends StatefulWidget {
  int recipeId;
  List<List<TextEditingController>> ingredientController;
  final List<Ingredient> ingredientDetail;
  List<bool> selected;

  IngredientTable({
    super.key,
    required this.recipeId,
    required this.ingredientController,
    required this.ingredientDetail,
    required this.selected,
  });

  
  @override
  State<IngredientTable> createState() => _IngredientTableState();
}

class _IngredientTableState extends State<IngredientTable> {
  
  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseProvider>(context).database;

    void DbUpdateIngredientName(int idx) {
      var oldName = widget.ingredientDetail[idx].name;
      var data = {'ingredient_name': widget.ingredientController[idx][0].text};
      db.update('recipe', data, where:'ingredient_name=?',whereArgs: [oldName]);
      db.update('ingredient', data, where:'ingredient_name=?',whereArgs: [oldName]);
      print('Db updated ingredient name');
    }

    void DbUpdateIngredientAmount(int idx, int recipeId) {
      var newAmount = widget.ingredientController[idx][1].text.trim();
      double newNumber;
      String newUnit;

      if (newAmount.split(' ').length == 2 ) {
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
      } catch(_){
        print('Couldn not parse unit');
        return;
      }
      db.update('recipe', {'ingredient_amount':newNumber, 'ingredient_unit': newUnit}, where:'recipe_id=?', whereArgs: [recipeId]);
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
            rows: widget.ingredientController.asMap().entries.map((entry) {
              int idx = entry.key;
              List<TextEditingController> i = entry.value;
              return DataRow(
                selected: widget.selected[idx],
                onSelectChanged: (bool? value) {
                  setState(() {
                    widget.selected[idx] = value!;
                    // print(Theme.of(context).dataTableTheme.dataTextStyle);
                  });
                },
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

RichText translateStepsToRichText(
    String step, Set<String> ingredients, context) {
  final words = step.split(' ');

  // put bold on numbers and the word after
  var boldIndex = List<bool>.generate(words.length, (i) => false);

  var trailing = false;
  for (var i = 0; i < words.length; i++) {
    var w = words[i];
    if (w.startsWith(RegExp(r'\d')) &
        !RegExp(r'[a-zA-Z]').hasMatch(w) &
        !w.endsWith('.')) {
      boldIndex[i] = true;
      trailing = true;
    } else if (trailing == true) {
      boldIndex[i] = true;
      trailing = false;
    }
  }
  // put font size, color variation on ingredients
  var ingredientIndex = words.map((w) {
    if (ingredients.contains(removeTrailing([',', '.'], w.toLowerCase()))) {
      return true;
    } else {
      return false;
    }
  }).toList();

  return RichText(
      text: TextSpan(
          children: words.asMap().entries.map((entries) {
    var idx = entries.key;
    var w = entries.value;
    if (boldIndex[idx]) {
      return TextSpan(
          text: '$w ',
          style: TextStyle(
              // fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              // decorationStyle: TextDecorationStyle.dashed,
              color: Theme.of(context).colorScheme.onPrimaryContainer));
    } else if (ingredientIndex[idx]) {
      return WidgetSpan(
          child: Text.rich(TextSpan(text: '$w '),
              textScaler: TextScaler.linear(1.05),
              textHeightBehavior:
                  TextHeightBehavior(applyHeightToLastDescent: false),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  leadingDistribution: TextLeadingDistribution.even,
                  // backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
                  color: Theme.of(context).colorScheme.onPrimaryContainer)));
    } else {
      return TextSpan(
          text: '$w ',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer));
    }
  }).toList()));
}

String doubleToString(double? n) {
  if (n == null) {
    return "-"; //stuff like pinch, garnish, to taste
  } else if (n % 1 != 0) {
    return n.toString();
  } else {
    return n.round().toString();
  }
}
