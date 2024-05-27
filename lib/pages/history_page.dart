import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxaero/pages/detail_page.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> invoices = [];
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    final url = Uri.parse('https://taxe.happook.com/api/invoices');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

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
        });

        // Imprimer les données de la première facture
        if (invoices.isNotEmpty) {
          print('Données de la première facture : ${invoices[0]}');
        }
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
          title: AppText(text: 'Historique de paiement'),
          centerTitle: true,
          actions: [
            GestureDetector(
              onTap: () {},
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
        body: invoices.isEmpty
            ? Container(
                decoration: const BoxDecoration(
                  image:  DecorationImage(
                    image: AssetImage('assets/nulldata.png'),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: invoices.length,
                itemBuilder: (BuildContext context, int index) {
                  // Récupérer les détails de la facture à partir de la liste invoices
                  Map<String, dynamic> invoice = invoices[index];

                  return Padding(
                    padding: const EdgeInsets.only(
                        left: 10.0, right: 10.0, top: 5.0),
                    child: GestureDetector(
                      onTap: () {
                        // Gérer la navigation vers la page de détail avec les détails de la facture
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              numero: invoice['reference'] ??
                                  '', // Utiliser la référence de la facture
                              date: DateFormat('yyyy-MM-dd HH:mm').format(
                                  DateTime.now()), // Utiliser la date actuelle
                              montant: invoice['bill'] ??
                                  '', // Utiliser le montant de la facture
                              taxateur: invoice['id'] ??
                                  '', // Utiliser le taxateur de la facture (s'il est disponible)
                              parking: invoice['ticket'] ??
                                  '', // Utiliser le ticket de la facture
                            ),
                          ),
                        );
                        print(invoice);
                      },
                      child: Card(
                        child: ListTile(
                          leading: Text(
                              (index + 1).toString()), // Numéroter le ListTile

                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: 'Montant: ${invoice['bill']}',
                                size: 14,
                              ),
                              AppText(
                                text: 'Référence: ${invoice['reference']}',
                                size: 14,
                              ),
                            ],
                          ),
                          trailing: AppText(
                            text: invoice['ticket'] ?? '',
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ));
  }
}
