import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'my_app_state.dart';
import 'recipe_page.dart';
import 'helper.dart';
import 'shared.dart';
import 'package:sqflite/sqflite.dart';

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
          searchRow(
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


class searchRow extends StatelessWidget {
  final Function() onChangeSelection;
  final List<String> listIngredients;

  const searchRow(
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
