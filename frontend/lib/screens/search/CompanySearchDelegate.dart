import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class OrganizationSearchDelegate extends SearchDelegate {
  final ApiService api = ApiService();

  OrganizationSearchDelegate();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = "",
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: api.searchOrganizations(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data as List;

        if (results.isEmpty) {
          return const Center(child: Text("No results found"));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, i) {
            final o = results[i];

            return ListTile(
              leading: const Icon(Icons.business),
              title: Text(o['name'] ?? ''),
              subtitle: Text("${o['city'] ?? ''} - ${o['country'] ?? ''}"),
              onTap: () => close(context, o),
            );
          },
        );
      },
    );
  }

@override
Widget buildSuggestions(BuildContext context) {
  if (query.isEmpty) {
    return const Center(
      child: Text("Search organizations..."),
    );
  }

  return FutureBuilder(
    future: api.searchOrganizations(query),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final results = snapshot.data as List;

      if (results.isEmpty) {
        return const Center(child: Text("No results"));
      }

      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, i) {
          final o = results[i];

          return ListTile(
            leading: const Icon(Icons.business),
            title: Text(o['name'] ?? ''),
            subtitle: Text("${o['city'] ?? ''} - ${o['country'] ?? ''}"),
            onTap: () {
              close(context, o);
            },
          );
        },
      );
    },
  );
}
}