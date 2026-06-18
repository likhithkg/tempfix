import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../l10n/app_localizations.dart';

class AutocompleteWidget extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSelected;

  const AutocompleteWidget({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  Future<List<String>> _getSuggestions(String query) async {

    query = query.trim();

    if (query.isEmpty) return [];

    try {

      final url =
          'https://us1.locationiq.com/v1/autocomplete.php?key=pk.56ccd9d8fb2cd5f3e9d7a656e3b52566&q=$query&countrycodes=in&limit=5&format=json';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);

      if (data is List) {
        return data
            .map<String>((item) => item['display_name'].toString())
            .toList();
      }

      return [];

    } catch (e) {

      return [];

    }
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(

      // 🔹 suggestions
      suggestionsCallback: _getSuggestions,

      // 🔹 builder for input field
      builder: (context, textEditingController, focusNode) {

        // keep controller synced
        textEditingController.text = controller.text;

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterLocationHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                textEditingController.clear();
              },
            ),
          ),
        );
      },

      // 🔹 suggestion UI
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(
            suggestion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },

      // 🔹 selection
      onSelected: (suggestion) {

        controller.text = suggestion;

        onSelected(suggestion);

      },

      // 🔹 loading indicator
      loadingBuilder: (context) => const Padding(
        padding: EdgeInsets.all(10),
        child: Center(child: CircularProgressIndicator()),
      ),

      // 🔹 empty UI
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Text(AppLocalizations.of(context)!.noLocationsFound),
      ),
    );
  }
}