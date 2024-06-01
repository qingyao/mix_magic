import 'dart:core';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

Future<Database> initializeDb() async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final path = join(documentsDirectory.path, 'data.db');

  // Delete the existing database (for development/debugging purposes)
  if (await File(path).exists()) {
    print('Deleting existing database...');
    await deleteDatabase(path);
  }

  // Load the database from the assets
  ByteData data = await rootBundle.load('assets/data.db');
  List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  // Write the database to the documents directory
  await File(path).writeAsBytes(bytes);
  print('Database copied from assets to $path');

  return openDatabase(
    path,
    // version: 1,
    // onCreate: (db, version) async {
    //   print('Creating table...');
    //   await db.execute('''
    //     CREATE TABLE items (
    //       id INTEGER PRIMARY KEY,
    //       name TEXT
    //     )
    //   ''');
    //   print('Table created');
    // },
  );
}

// Future<void> insertRecipe(Database db) async {
//   print('inserting recipe...');
//   await db.insert('Recipe', {'name': 'Recipe Sample'});
// }

Future<List<int>> getRecipesByIngredients(
    Database db, Set<String> ingredients) async {
  print(ingredients);
  List<int> ingredientIds = [];
  for (var ingredient in ingredients) {
    var ingredientId = hashStringToInt(ingredient.toLowerCase());
    ingredientIds.add(ingredientId);
  }

  var recipes = await db.query('mixmatch',
      where:
          'ingredient_id IN (${List.filled(ingredientIds.length, '?').join(',')})',
      whereArgs: ingredientIds);

  var recipeIds = <int>{};
  for (var recipe in recipes) {
    recipeIds.add(recipe['recipe_id'] as int);
  }
  return recipeIds.toList();
}

Future<String> getRecipeDetail(Database db, int recipeId) async {
  var recipes = await db
      .query('recipe_detail', where: 'recipe_id=?', whereArgs: [recipeId]);

  return recipes[0]['steps'] as String;
}

Future<String> getRecipeName(Database db, int recipeId) async {
  var recipes = await db
      .query('recipe_detail', where: 'recipe_id=?', whereArgs: [recipeId]);

  return recipes[0]['recipe_title'] as String;
}

Future<List<String>> getAllIngredients(Database db) async {
  var ingredients = await db.query('ingredient');
  var listIngredients = <String>[];
  for (var ingredient in ingredients) {
    var tmp = ingredient['ingredient_name'] as String;
    listIngredients.add(tmp.toLowerCase());
  }
  return listIngredients;
}

Future<List<Ingredient>> getIngredientDetail(Database db, int recipeId) async {
  var ingredients =
      await db.query('recipe', where: 'recipe_id=?', whereArgs: [recipeId]);

  print(ingredients.map((i) => i.toString()));
  return ingredients
      .map((i) => Ingredient(
            name: i['ingredient_name'] as String,
            amount: i['ingredient_amount'] as double?,
            unit: i['ingredient_unit'] as String,
          ))
      .toList();
}

Future<List<Map<String, dynamic>>> getRecipes(Database db) async {
  return await db.query('recipe');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // var documentsDirectory = await getApplicationDocumentsDirectory();
  // var newPath = join(documentsDirectory.path, '/created.db');
  // var newPath = await getDatabasesPath();

  Database db = await initializeDb();

  // Insert an example item
  // try {
  //   await insertRecipe(db);
  //   print('Recipe inserted');
  // } catch (e) {
  //   print('Error inserting Recipe: $e');
  // }

  // Retrieve and print items
  try {
    final items = await getRecipesByIngredients(db, {'canola oil'});
    print('Recipe Ids: $items');
  } catch (e) {
    print('Error retrieving Recipe: $e');
  }

  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final Database db;
  const MyApp({super.key, required this.db});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => MyAppState(),
          ),
          ChangeNotifierProvider(create: (context) => DatabaseProvider(db))
        ],
        child: MaterialApp(
          title: 'Mix Magic',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightGreen, brightness: Brightness.light),
            useMaterial3: true,
            /* light theme settings */
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightGreen, brightness: Brightness.dark),
            useMaterial3: true,
            /* dark theme settings */
          ),
          themeMode: ThemeMode.system,
          home: const MyHomePage(),
        ));
  }
}

// ...

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            title: Container(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'Mix Magic',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ))),
        body: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const GeneratorPage(),
        ),
      );
    });
  }
}

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  List<int> recipeIds = [];
  List<String> names = [];
  List<String> images = [];
  List<String> listIngredients = [];
  List<Ingredient> ingredientDetail = [];
  String stepsDetail = '';
  bool isLoading = false;
  String stateData = "Initial state";
  // final stepsDetail = "1. wash broccoli. \n2. cook";

  bool listIngredientInitialized = false;

  Future<void> _initializeAsyncDependencies(Database db) async {
    // Fetch the database from the context after the first build
    final tmp = await getAllIngredients(db);
    // print(tmp);
    print(removeTrailing(['.', ','], 'abc.'));
    // Perform your asynchronous operation with the database
    // Update the state with the fetched data
    setState(() {
      listIngredients = tmp;
      listIngredientInitialized = true;
    });
  }

  Future<String> _checkImage(String image) async {
    try {
      await rootBundle.load(image);
      return image;
    } catch (e) {
      return 'assets/example.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseProvider>(context).database;

    // db is available here but ingredients are needed for autocomplete
    // callback allows immediately loading ingredients after context is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!listIngredientInitialized) {
        _initializeAsyncDependencies(db);
      }
    });

    var appState = context.watch<MyAppState>();

    void updateId() async {
      //reset images and names
      images = [];
      names = [];
      print("I'm updating recipes!");
      recipeIds = await getRecipesByIngredients(db, appState.selection);
      for (var recipeId in recipeIds) {
        var recipeName = await getRecipeName(db, recipeId);
        // check if image exists
        String image =
            await _checkImage('assets/${recipeName.replaceAll(' ', '-')}.png');
        setState(() {
          names.add(recipeName);
          images.add(image);
        });
      }
    }

    void navigateToNextPage(int index) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipePage(
              recipeName: names[index],
              ingredientDetail: ingredientDetail,
              stepsDetail: stepsDetail),
          // settings: const RouteSettings(
          //   arguments: {recipe_detail},
          // ),
        ),
      ).then((value) {
        // is triggered when coming back Nagivator.pop(context, value)
        setState(() {
          stateData = value ?? stateData;
        });
      });
    }

    void getIngredientSteps(Database db, int recipeId, int index) async {
      setState(() {
        isLoading = true;
      });
      ingredientDetail = await getIngredientDetail(db, recipeId);
      stepsDetail = await getRecipeDetail(db, recipeId);
      setState(() {
        isLoading = false;
      });
      navigateToNextPage(index);
    }

    return SafeArea(
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Search ingredients'),
              ),
            ],
          ),
          IngredientRow(
            onChangeSelection: updateId,
            listIngredients: listIngredients,
          ),
          const SizedBox(
            height: 50,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Recipe'),
            ],
          ),
          // Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: ElevatedButton(
          //       onPressed: _addNewId,
          //       child: const Text('Add New ID'),
          //     ),
          //   ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                // crossAxisCount: 2, // Number of columns
                mainAxisSpacing: 20, // Spacing between rows
                crossAxisSpacing: 20, // Spacing between columns
                childAspectRatio:
                    0.8, // Width to height ratio of the grid items
              ),
              padding: const EdgeInsets.all(30),
              itemCount: names.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                12), // Adjust the radius for rounded corners
                          ),
                        ),
                        onPressed: () {
                          // Handle button press
                          getIngredientSteps(db, recipeIds[index], index);
                          // debugPrint('Button with ID: ${ids[index]} pressed');
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            images[index],
                            fit: BoxFit.cover,
                          ),
                        )),
                    Expanded(child: Text(names[index])),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecipePage extends StatelessWidget {
  final String recipeName;
  final List<Ingredient> ingredientDetail;
  final String stepsDetail;
  final LineSplitter ls = const LineSplitter();

  const RecipePage(
      {super.key,
      required this.recipeName,
      required this.ingredientDetail,
      required this.stepsDetail});

  @override
  Widget build(BuildContext context) {
    // const ingredientText = "broccoli 500g\ntofu 200g\n";
    var ingredientList = ingredientDetail.map((i) {
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
                recipeName, //'Tom ka gai',
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
                    Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: IngredientTable(
                                  selected: List<bool>.generate(
                                      ingredientDetail.length,
                                      (int index) => false),
                                  ingredientDetail: ingredientDetail),
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
                              .convert(stepsDetail)
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

class IngredientRow extends StatelessWidget {
  final Function() onChangeSelection;
  final List<String> listIngredients;

  const IngredientRow(
      {super.key,
      required this.onChangeSelection,
      required this.listIngredients});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment
                .center, // not to take all available horizontal space
            children: <Widget>[
              AutocompleteBasicExample(
                onChangeSelection: onChangeSelection,
                listIngredients: listIngredients,
                fieldId: 0,
              ), // Example widget from the link
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment
                .center, // not to take all available horizontal space
            children: <Widget>[
              AutocompleteBasicExample(
                  onChangeSelection: onChangeSelection,
                  listIngredients: listIngredients,
                  fieldId: 1), // Example widget from the link
            ],
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}

// ...

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var selectionMap = <int, String>{};
  var selection = <String>{};
  void passSelected(fieldId, selected) {
    selectionMap[fieldId] = selected;
    selection = selectionMap.values.toSet();
    debugPrint(selection.join(','));
    // _triggerRefresh();
  }

  // void _triggerRefresh() {
  //   print('AppState property changed to');
  // }
}

class AutocompleteBasicExample extends StatelessWidget {
  final Function() onChangeSelection;
  final List<String> listIngredients;
  final int fieldId;

  const AutocompleteBasicExample(
      {super.key,
      required this.onChangeSelection,
      required this.listIngredients,
      required this.fieldId});

  // static const List<String> _kOptions = <String>[
  //   'broccoli',
  //   'chicken',
  //   'tofu',
  // ];
  // final List<String> _kOptions = listIngredients;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return listIngredients.where((String option) {
          return option
              .split(' ')
              .any((i) => i.startsWith(textEditingValue.text.toLowerCase()));
        });
      },
      onSelected: (String selected) {
        appState.passSelected(fieldId, selected);
        onChangeSelection();
      },
    );
  }
}

class DatabaseProvider with ChangeNotifier {
  final Database database;

  DatabaseProvider(this.database);

  // Additional methods to interact with the database can be added here.
}

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

int hashStringToInt(String name) {
  List<int> bytes = utf8.encode(name);
  Digest md5Hash = md5.convert(bytes);
  String hexSubString = md5Hash.toString().substring(0, 6);
  int converted = int.parse(hexSubString, radix: 16);
  return converted;
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
      return TextSpan(
          text: '$w ',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              // backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
              color: Theme.of(context).colorScheme.onPrimaryContainer));
    } else {
      return TextSpan(
          text: '$w ',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer));
    }
  }).toList()));
}

String removeTrailing(List<String> pattern, String from) {
  if (pattern.isEmpty) return from;
  var i = from.length;
  var dontFind = 0;
  while (dontFind != pattern.length) {
    dontFind = 0;
    for (var p in pattern) {
      if (from.startsWith(p, i - p.length)) {
        i -= p.length;
        break;
      }
      dontFind++;
    }
  }

  return from.substring(0, i);
}
