// ignore_for_file: use_super_parameters, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/app_text_large.dart';

class HistoryPage extends StatelessWidget {
  HistoryPage({Key? key}) : super(key: key);

  final List<String> number = ['1', '2', '3', '4', '5', '6', '7'];
  final List<String> name = [
    'AKONKWA JUSTIN ',
    'KASSE CHRISTIAN',
    'BINJA GISELE',
    'PACOME CUMA',
    'EMMANUEL NKANDA',
    'PACOME CUMA',
    'EMMANUEL NKANDA'
  ];
  final List<String> compagnie = [
    'Air France ',
    'C A A ',
    'Congo Airways ',
    ' Kanya Airways ',
    'Ethiopien Airways ',
    'C A A ',
    'Congo Airways ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: true,
        title: AppText(text: 'Historique de payement'),
         centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              showSearch(context: context, delegate: SearchBar());
            },
            child: Card(
              child: Container(
                height: 40,
                width: 40,
                child: Icon(
                  Icons.search,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: number.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/detail');
              },
              child: Card(
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextLarge(
                        text: name[index],
                        size: 16,
                      ),
                     
                    ],
                  ),
                  leading: AppText(text: number[index]),
                  trailing:  AppText(text: compagnie[index]),
                  subtitle: AppText(text: "12 /05/ 2024 à 12h 45'"),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SearchBar extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Your search query: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestions = [
      'AKONKWA JUSTIN ',
      'KASSE CHRISTIAN',
      'BINJA GISELE',
      'PACOME CUMA',
      'EMMANUEL NKANDA'
    ];
    final List<String> filteredSuggestions =
        suggestions.where((suggestion) => suggestion.contains(query)).toList();

    return ListView.builder(
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return ListTile(
          title: Text(suggestion),
          onTap: () {
            close(context, suggestion);
          },
        );
      },
    );
  }
}
