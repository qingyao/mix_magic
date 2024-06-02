# mix_magic

This is a multi-platform App to perform multiple ingredient search in the existing recipes.
- tested for iOS and android, also should work on macOS and Windows App
- Does not support Web App due to limitation of sqflite library incompatibility

## Main feature
With input of ingredients, the App shows the recipes with image title and cooking time dynamically and features selection and expansion of the entire recipe in the next page and page return for re-selection.

## Future development
- API for GPT will be connected to allow user to take a picture. The output will be parsed for user to edit and save in the recipe database and part of image will be cropped as recipe logo.
- Ingredient replacement will be suggested based on a replacement table.
- Filter category of recipe savory dish, sweet dessert, basic, salad etc.
- Toggle master (template) recipes which tolerate ingredient replacements based on broad category.
- Toggle filter for short/long duration recipes
- Normalize multiple ingredients to one canonical ingredient. e.g. Rock salt, Kosher salt, sea salt -> salt.

## Technology
Flutter framework with Dart
SQLite database with sqflite plug-in

Resources for reference:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
