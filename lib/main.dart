import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'my_app_state.dart';
import 'generator_page.dart';
import 'helper.dart';
import 'shared.dart';
import 'add_recipe_page.dart';

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
                //8BC34A
                seedColor: Colors.lightGreen,
                brightness: Brightness.light,
                //#c34a8b, #c34a4e
                secondary: const Color(0xFF824AC3)),
            useMaterial3: true,
            /* light theme settings */
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightGreen,
                brightness: Brightness.dark,
                secondary: const Color(0xFF824AC3)),
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
  var _selectedIndex = 0;
  Widget page = const GeneratorPage();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (_selectedIndex) {
      case 0:
        page = const GeneratorPage();
        break;
      case 1:
        page = const AddRecipePage();
        break;
      default:
        throw UnimplementedError('no widget for $_selectedIndex');
    }
    });
  }

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
          child: page,
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search Recipe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_document),
              label: 'Add recipe',
            )
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      );
    });
  }
}
