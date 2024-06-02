import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'my_app_state.dart';
import 'helper.dart';
import 'shared.dart';

class RecipePage extends StatefulWidget {
  String recipeName;
  List<Ingredient> ingredientDetail;
  final String stepsDetail;

  RecipePage(
      {super.key,
      required this.recipeName,
      required this.ingredientDetail,
      required this.stepsDetail});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final LineSplitter ls = const LineSplitter();

  @override
  Widget build(BuildContext context) {
    // const ingredientText = "broccoli 500g\ntofu 200g\n";
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
                    Container(child: Text(widget.recipeName, textScaler: TextScaler.linear(1.2)), padding: EdgeInsets.all(10.0),),
                    Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: IngredientTable(
                                  selected: List<bool>.generate(
                                      widget.ingredientDetail.length,
                                      (int index) => false),
                                  ingredientDetail: widget.ingredientDetail),
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
  final List<Ingredient> ingredientDetail;
  List<bool> selected;

  IngredientTable({
    super.key,
    required this.ingredientDetail,
    required this.selected,
  });

  @override
  State<IngredientTable> createState() => _IngredientTableState();
}

class _IngredientTableState extends State<IngredientTable> {
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
                selected: widget.selected[idx],
                onSelectChanged: (bool? value) {
                  setState(() {
                    widget.selected[idx] = value!;
                    // print(Theme.of(context).dataTableTheme.dataTextStyle);
                  });
                },
                cells: [
                  DataCell(Text(i.name,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer))),
                  DataCell(Text(
                    "${doubleToString(i.amount)} ${i.unit}",
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
    if (w.startsWith(RegExp(r'\d')) & !RegExp(r'[a-zA-Z]').hasMatch(w)) {
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
        child:Text.rich(
          TextSpan(text:'$w ') ,
          textScaler: TextScaler.linear(1.05),
          textHeightBehavior: TextHeightBehavior(applyHeightToLastDescent:false),
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

