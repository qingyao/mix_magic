import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'helper.dart';
import 'shared.dart';
import 'ingredient_table.dart';

class RecipePage extends StatefulWidget {
  int recipeId;
  String recipeName;
  List<Ingredient> ingredientDetail;
  final String stepsDetail;

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
  String buttonText = 'Edit';
  Icon buttonIcon = const Icon(Icons.edit);
  late Widget table;
  late EditIngredientTable editIngredientTable;
  late IngredientTable ingredientTable;

  @override
  void initState() {
    super.initState();
    ingredientTable = IngredientTable(
      recipeId: widget.recipeId,
      ingredientDetail: widget.ingredientDetail,
    );
    table = ingredientTable;
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseProvider>(context).database;

    void toggleEdit() async {
      
      if (buttonText == 'Edit') {
        // current state is reading

        editIngredientTable = EditIngredientTable(
            recipeId: widget.recipeId,
            ingredientDetail: widget.ingredientDetail);
        setState(() {
          buttonText = 'Done';
          table = editIngredientTable;
          buttonIcon = const Icon(Icons.check);
        });
      } else {
        // current state is editing

        var ingredientDetail = await getIngredientDetail(db, widget.recipeId);
        // print("I'm updating ingredient table");
        setState(() {
          widget.ingredientDetail = ingredientDetail;
          ingredientTable = IngredientTable(
            recipeId: widget.recipeId,
            ingredientDetail: widget.ingredientDetail,
          );
          buttonText = 'Edit';
          table = ingredientTable;
          buttonIcon = const Icon(Icons.edit);
        });
        
      }
    }

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
              color: Theme.of(context).colorScheme.onPrimary,
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
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(widget.recipeName,
                                textScaler: const TextScaler.linear(1.5)),
                          ),
                        ),
                        IconButton(
                          onPressed: toggleEdit,
                          icon: buttonIcon,
                        ) //label:Text(buttonText)
                      ],
                    ),
                    Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: table,
                            )
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
