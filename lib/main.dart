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

Future<List<int>> getRecipesByIngredient(Database db, String ingredient) async {
  var ingredientId = hashStringToInt(ingredient.toLowerCase());
  var recipes = await db.query('recipe', where: 'ingredient_id=?', whereArgs: [ingredientId]);
  var recipe_ids = <int>[];
  for (var recipe in recipes){
    recipe_ids.add(recipe['recipe_id'] as int);
  }
  return recipe_ids;
}

Future<List<Map<String, dynamic>>> getRecipes(Database db) async {
  return await db.query('recipe');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // var documentsDirectory = await getApplicationDocumentsDirectory();
  // var newPath = join(documentsDirectory.path, '/created.db');
  // var newPath = await getDatabasesPath();
  
  final db = await initializeDb();
  
  // Insert an example item
  // try {
  //   await insertRecipe(db);
  //   print('Recipe inserted');
  // } catch (e) {
  //   print('Error inserting Recipe: $e');
  // }

  // Retrieve and print items
  try {
    final items = await getRecipesByIngredient(db, 'canola oil');
    print('Recipe Ids: $items');
  } catch (e) {
    print('Error retrieving Recipe: $e');
  }

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
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
            title: const Text('Mix Magic'),
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
  var counter = 1;

  void _addNewId() {
    setState(() {
      // Add a new ID (for example purposes, using a timestamp)
      ids.add(counter++);
      names.add('Recipe');
      images.add('assets/example.png');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    String stateData = "Initial state";

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
          const IngredientRow(),
          const SizedBox(height: 50,),
          const Row(
            mainAxisAlignment:MainAxisAlignment.center,
            children: [
            Text('Recipe'),
            ],
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _addNewId,
                child: const Text('Add New ID'),
              ),
            ),
          Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  mainAxisSpacing: 20, // Spacing between rows
                  crossAxisSpacing: 20, // Spacing between columns
                  childAspectRatio: 0.85, // Width to height ratio of the grid items
                ),
                padding: const EdgeInsets.all(30),
                itemCount: ids.length,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RecipePage()),
                          ).then((value){
                            // to persist the state or change it when coming back
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
                      Text(names[index]),
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
            style: Theme.of(context).textTheme.headlineMedium,
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
  const IngredientRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        SizedBox(width: 20),
         Expanded(
           child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center, // not to take all available horizontal space
                    children:  <Widget>[
                      
                      AutocompleteBasicExample(), // Example widget from the link
                    ],
                  ),
         ),
         SizedBox(width: 20),
         Expanded(
           child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center, // not to take all available horizontal space
                    children:  <Widget>[
                      
                      AutocompleteBasicExample(), // Example widget from the link
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

  var selection = <String>{};
  void passSelected (selected) {
    selection.add(selected);
    debugPrint(selection.toList().join(','));
  }
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
  const AutocompleteBasicExample({super.key});
  
  static const List<String> _kOptions = <String>[
    'broccoli',
    'chicken',
    'tofu',
  ];

  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return _kOptions.where((String option) {
          return option.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selected) {
        // debugPrint('You just selected $selection');
        appState.passSelected(selected);
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