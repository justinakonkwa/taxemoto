import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:taxaero/pages/detail_page.dart';

class HistoryPage extends StatefulWidget {
  HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> invoices = [];
  bool isLoading = false;
  bool hasData = false;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() {
        invoices = prefs.getStringList('invoices')?.map((e) => jsonDecode(e)).toList() ?? [];
        hasData = invoices.isNotEmpty;
      });
      return;
    }

    final url = Uri.parse('https://taxe.happook.com/api/invoices');

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        List<dynamic> invoicesList = responseData['hydra:member'] ?? [];
        setState(() {
          invoices = invoicesList;
          hasData = invoices.isNotEmpty;
        });

        prefs.setStringList('invoices', invoices.map((e) => jsonEncode(e)).toList());
      } else {
        throw Exception('Failed to load invoices');
      }
    } catch (e) {
      print('Error fetching invoices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: true,
        title: const Text('Historique de paiement'),
        centerTitle: true,
      ),
      body: !hasData
          ? Center(
              child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/nulldata.png'),
                    ),
                  ),
                )
            )
          : invoices.isEmpty
              ? const Center(
                  child: Text('Aucune donnée disponible'),
                )
              : ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (BuildContext context, int index) {
                    invoices.sort((a, b) => b['createdAt'].compareTo(a['createdAt'])); // Tri décroissant

                    Map<String, dynamic> invoice = invoices[index];

                    String formattedDate = '';
                    if (invoice['createdAt'] != null) {
                      DateTime parsedDate = DateTime.parse(invoice['createdAt']);
                      formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
                      DateTime gmtPlusOneDate = parsedDate.add(const Duration(hours: 1));
                      formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(gmtPlusOneDate);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 5.0),
                      child: Card(
                        child: ListTile(
                          leading: Text((index + 1).toString()), // Numéroter le ListTile
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Montant: ${invoice['bill']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Référence: ${invoice['reference']}',
                                style: const TextStyle(),
                              ),
                            ],
                          ),
                          trailing: Text(
                            invoice['ticket'] ?? '',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  numero: invoice['reference'] ?? '', 
                                  date: formattedDate,
                                  montant: invoice['bill'] ?? '', 
                                  taxateur: invoice['id'] ?? '', 
                                  parking: invoice['ticket'] ?? '',
                                ),
                              ),
                            );
                            print(invoice);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
