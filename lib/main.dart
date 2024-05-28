import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

Future<Database> initializeDb() async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final path = join(documentsDirectory.path, 'example.db');
  
  // Delete the existing database (for development/debugging purposes)
  if (await File(path).exists()) {
    print('Deleting existing database...');
    await deleteDatabase(path);
  }

  // Load the database from the assets
  ByteData data = await rootBundle.load('assets/data.db');
  List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

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

Future<Set<int>> getRecipesByIngredients(Database db, Set<String> ingredients) async {
  print(ingredients);
  List<int> ingredientIds = [];
  for (var ingredient in ingredients) {
    var ingredientId = hashStringToInt(ingredient.toLowerCase());
    ingredientIds.add(ingredientId);
  }
  
  var recipes = await db.query('mixmatch', 
        where: 'ingredient_id IN (${List.filled(ingredientIds.length, '?').join(',')})', 
        whereArgs: ingredientIds);

  var recipeIds = <int>{};
  for (var recipe in recipes){
    recipeIds.add(recipe['recipe_id'] as int);
  }
  return recipeIds;
}
// Future<List> getRecipeDetail()


Future<String> getRecipeName(Database db, int recipeId) async {
  
  var recipes = await db.query('recipe_detail', 
          where: 'recipe_id=?', 
          whereArgs: [recipeId]);
          
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

  runApp(MyApp(db:db));
}


class MyApp extends StatelessWidget {
  final Database db;
  const MyApp({super.key, required this.db});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      
      providers:[
        ChangeNotifierProvider(create: (context) => MyAppState(),),
        ChangeNotifierProvider(create: (context) => DatabaseProvider(db))
      ] ,
      child: MaterialApp(
        title: 'Mix Magic',
        theme: ThemeData(
          
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      )
    );
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            title: Container(
              padding: const EdgeInsets.all(10),
              child:  Text('Mix Magic',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                )
              )
            ),
          body: 
              Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const GeneratorPage(),
                ),
              );
      }
    );
  }
}


class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  
  List<int> ids = [];
  List<String> names = [];
  List<String> images = [];
  List<String> listIngredients = [];
  bool listIngredientInitialized = false;
  
  Future<void> _initializeAsyncDependencies(Database db) async {
    // Fetch the database from the context after the first build
    final tmp = await getAllIngredients(db);
    print(tmp);

    // Perform your asynchronous operation with the database
    // Update the state with the fetched data
    setState(() {
      listIngredients = tmp;
      listIngredientInitialized = true;
    });
  }
  @override
  Widget build(BuildContext context) {
    String stateData = "Initial state";
    
    final db = Provider.of<DatabaseProvider>(context).database;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (! listIngredientInitialized ){
        _initializeAsyncDependencies(db);
      }
    }
    );

    var appState = context.watch<MyAppState>();

    void _updateId () async {
      images = [];
      names = [];
      print("I'm updating!");
      var recipeIds = await getRecipesByIngredients(db, appState.selection);
      for (var recipeId in recipeIds) {
        var recipeName =  await getRecipeName(db, recipeId);
        setState(() {
          names.add(recipeName);
          images.add('assets/example.png');
        });
      }  
    }

    
    return SafeArea(
      child: Column(
        children: [
          const Row(
            mainAxisAlignment:MainAxisAlignment.center,
            children: [
             Padding(
               padding: EdgeInsets.all(20.0),
               child: Text('Search ingredients'),
             ),
            ],
          ),
          IngredientRow(onChangeSelection: _updateId, listIngredients: listIngredients,),
          const SizedBox(height: 50,),
          const Row(
            mainAxisAlignment:MainAxisAlignment.center,
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
                  childAspectRatio: 0.8, // Width to height ratio of the grid items
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
                            borderRadius: BorderRadius.circular(12), // Adjust the radius for rounded corners
                          ),
                        ),
                        onPressed: () {
                          // Handle button press

                          // var recipe_detail = await getRecipeDetail(recipeIds[index]);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RecipePage(),
                            // settings: const RouteSettings(
                            //   arguments: {recipe_detail},
                            // ),
                            ),
                          ).then((value){
                            // is triggered when coming back Nagivator.pop(context, value)
                            setState(() {
                              stateData = value ?? stateData;
                            });
                          });
                          // debugPrint('Button with ID: ${ids[index]} pressed');
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            images[index], 
                            fit: BoxFit.cover,),
                        )
                      ),
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
  const RecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    const ingredientText = "broccoli 500g\ntofu 200g\n";
    return PopScope(
      canPop: false,
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
            'Tom ka gai',
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
              const Row(children: [
                Expanded(child: Text(ingredientText, textAlign: TextAlign.center)),
                Expanded(
                    child: FittedBox(
                      child: FlutterLogo(),
                    ),
                  ),
              ],),
              const Text("30min"),
              Container
              (padding: const EdgeInsets.all(15),
               child: const Text("1. wash broccoli. \n2. cook",textAlign: TextAlign.left,)
               )
            ],),
        )
        
        )
        ),
    );
  }

}

class IngredientRow extends StatelessWidget {
  final Function() onChangeSelection;
  final List<String> listIngredients;

  const IngredientRow({
    super.key,
    required this.onChangeSelection,
    required this.listIngredients
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        SizedBox(width: 20),
         Expanded(
           child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center, // not to take all available horizontal space
                    children:  <Widget>[
                      
                      AutocompleteBasicExample(onChangeSelection: onChangeSelection, 
                      listIngredients: listIngredients,
                      fieldId: 0,), // Example widget from the link
                    ],
                  ),
         ),
         SizedBox(width: 20),
         Expanded(
           child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center, // not to take all available horizontal space
                    children:  <Widget>[
                      
                      AutocompleteBasicExample(onChangeSelection: onChangeSelection, 
                      listIngredients: listIngredients,
                      fieldId: 1), // Example widget from the link
                    ],
                  ),
         ),
         SizedBox(width: 20),
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

  var selectionMap = <int,String>{};
  var selection = <String>{};
  void passSelected (fieldId, selected) {
    selectionMap[fieldId]=selected;
    selection = selectionMap.values.toSet();
    debugPrint(selection.join(','));
    // _triggerRefresh();
  }

  // void _triggerRefresh() {
  //   print('AppState property changed to');
  // }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      fontFamily: 'helvetica',
      color:theme.colorScheme.onPrimary, // change the color but keep the rest
    );

    return Card(
      color: theme.colorScheme.primary,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asSnakeCase, 
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}", //for VoiceOver to read correctly
          ),
      ),
    );
  }
}

class AutocompleteBasicExample extends StatelessWidget {
  final Function() onChangeSelection;
  final List<String> listIngredients;
  final int fieldId;

  const AutocompleteBasicExample({super.key, 
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
          return option.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selected) {
        
        appState.passSelected(fieldId, selected);
        onChangeSelection();
      },
    );
  }
}

int hashStringToInt(String name) {
  List<int> bytes = utf8.encode(name);
  Digest md5Hash = md5.convert(bytes);
  String hexSubString = md5Hash.toString().substring(0,6);
  int converted = int.parse(hexSubString, radix:16);
  return converted;
}

class DatabaseProvider with ChangeNotifier {
  final Database database;

  DatabaseProvider(this.database);

  // Additional methods to interact with the database can be added here.
}