import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AutocompleteWidget extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSelected;

  const AutocompleteWidget({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  Future<List<String>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url =
        'https://us1.locationiq.com/v1/autocomplete.php?key=pk.56ccd9d8fb2cd5f3e9d7a656e3b52566&q=$query&countrycodes=in&format=json';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    return data.map<String>((item) => item['display_name'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      // 🔹 new API: use builder for TextField
      builder: (context, textEditingController, focusNode) {
        return TextField(
          controller: controller, // still using your passed controller
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Enter location...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            ),
          ),
        );
      },

      // 🔹 suggestions callback
      suggestionsCallback: _getSuggestions,

      // 🔹 how each suggestion looks
      itemBuilder: (context, suggestion) => ListTile(
        title: Text(suggestion),
      ),

      // 🔹 when user selects a suggestion
      onSelected: onSelected,
    );
  }
}