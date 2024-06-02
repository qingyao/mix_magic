import 'shared.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';

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

int hashStringToInt(String name) {
  List<int> bytes = utf8.encode(name);
  Digest md5Hash = md5.convert(bytes);
  String hexSubString = md5Hash.toString().substring(0, 6);
  int converted = int.parse(hexSubString, radix: 16);
  return converted;
}
