// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:taxaero/pages/detail_page.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/app_text_large.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> invoices = [];
  bool isLoading = true;
  bool hasData = false;

  @override
  void initState() {
    super.initState();
    fetchAllInvoices();
  }

  Future<void> fetchAllInvoices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() {
        invoices = prefs
                .getStringList('invoices')
                ?.map((e) => jsonDecode(e))
                .toList() ??
            [];
        filterInvoicesForToday();
        isLoading = false;
      });
      return;
    }

    List<dynamic> allInvoices = [];
    int page = 1;
    bool morePagesAvailable = true;

    while (morePagesAvailable) {
      final url = Uri.parse('https://taxe.happook.com/api/invoices?page=$page');

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

          if (invoicesList.isEmpty) {
            morePagesAvailable = false;
          } else {
            allInvoices.addAll(invoicesList);
            page++;
          }
        } else {
          throw Exception('Failed to load invoices');
        }
      } catch (e) {
        print('Error fetching invoices: $e');
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    setState(() {
      invoices = allInvoices;
      filterInvoicesForToday();
      isLoading = false;
    });

    prefs.setStringList(
        'invoices', invoices.map((e) => jsonEncode(e)).toList());
  }

  void filterInvoicesForToday() {
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    invoices = invoices.where((invoice) {
      if (invoice['createdAt'] != null) {
        DateTime invoiceDate = DateTime.parse(invoice['createdAt']);
        return invoiceDate.isAfter(startOfToday);
      }
      return false;
    }).toList();

    setState(() {
      hasData = invoices.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        title: AppTextLarge(text: 'Historique de paiement'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: Image.asset('assets/intro4.png'),
                  ),
                  AppText(text: '... chargement.')
                ],
              ),
            )
          : !hasData
              ? const Center(child: Text('Aucune donnée disponible'))
              : ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (BuildContext context, int index) {
                    invoices.sort((a, b) => b['createdAt']
                        .compareTo(a['createdAt'])); // Tri décroissant

                    Map<String, dynamic> invoice = invoices[index];

                    String formattedDate = '';
                    if (invoice['createdAt'] != null) {
                      DateTime parsedDate =
                          DateTime.parse(invoice['createdAt']);
                      formattedDate =
                          DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
                      DateTime gmtPlusOneDate =
                          parsedDate.add(const Duration(hours: 1));
                      formattedDate =
                          DateFormat('yyyy-MM-dd HH:mm').format(gmtPlusOneDate);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      child: Card(
                        child: ListTile(
                          leading: Text(
                              (index + 1).toString()), // Numéroter le ListTile
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Montant: ${invoice['amount']}',
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
                                  amount: invoice['amount'] ?? '',
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

class SalesData {
  SalesData(this.year, this.sales);

  final String year;
  final double sales;
}


// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// import 'package:taxaero/pages/detail_page.dart';
// import 'package:taxaero/widget/app_text.dart';
// import 'package:taxaero/widget/app_text_large.dart';

// class HistoryPage extends StatefulWidget {
//   const HistoryPage({Key? key}) : super(key: key);

//   @override
//   _HistoryPageState createState() => _HistoryPageState();
// }

// class _HistoryPageState extends State<HistoryPage> {
//   List<dynamic> invoices = [];
//   bool isLoading = true;
//   bool hasData = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchAllInvoices();
//   }

//   Future<void> fetchAllInvoices() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');

//     if (token == null) {
//       setState(() {
//         invoices = prefs
//                 .getStringList('invoices')
//                 ?.map((e) => jsonDecode(e))
//                 .toList() ??
//             [];
//         hasData = invoices.isNotEmpty;
//         isLoading = false;
//       });
//       return;
//     }

//     List<dynamic> allInvoices = [];
//     int page = 1;
//     bool morePagesAvailable = true;

//     while (morePagesAvailable) {
//       final url = Uri.parse('https://taxe.happook.com/api/invoices?page=$page');

//       try {
//         final response = await http.get(
//           url,
//           headers: <String, String>{
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         );

//         if (response.statusCode == 200) {
//           Map<String, dynamic> responseData = jsonDecode(response.body);
//           List<dynamic> invoicesList = responseData['hydra:member'] ?? [];

//           if (invoicesList.isEmpty) {
//             morePagesAvailable = false;
//           } else {
//             allInvoices.addAll(invoicesList);
//             page++;
//           }
//         } else {
//           throw Exception('Failed to load invoices');
//         }
//       } catch (e) {
//         print('Error fetching invoices: $e');
//         setState(() {
//           isLoading = false;
//         });
//         return;
//       }
//     }

//     setState(() {
//       invoices = allInvoices;
//       hasData = invoices.isNotEmpty;
//       isLoading = false;
//     });

//     prefs.setStringList(
//         'invoices', invoices.map((e) => jsonEncode(e)).toList());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0.0,
//         automaticallyImplyLeading: false,
//         title:  AppTextLarge(text: 'Historique de paiement'),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ?  Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                       width: 200,
//                       child: Image.asset('assets/intro4.png'),
//                     ),
//                     AppText(text: '... chargement.')
//               ],
//             ),
//           )
//           : !hasData
//               ? const Center(child: Text('Aucune donnée disponible'))
//               : ListView.builder(
//                   itemCount: invoices.length,
//                   itemBuilder: (BuildContext context, int index) {
//                     invoices.sort((a, b) => b['createdAt']
//                         .compareTo(a['createdAt'])); // Tri décroissant

//                     Map<String, dynamic> invoice = invoices[index];

//                     String formattedDate = '';
//                     if (invoice['createdAt'] != null) {
//                       DateTime parsedDate =
//                           DateTime.parse(invoice['createdAt']);
//                       formattedDate =
//                           DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
//                       DateTime gmtPlusOneDate =
//                           parsedDate.add(const Duration(hours: 1));
//                       formattedDate =
//                           DateFormat('yyyy-MM-dd HH:mm').format(gmtPlusOneDate);
//                     }

//                     return Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10.0, vertical: 5.0),
//                       child: Card(
//                         child: ListTile(
//                           leading: Text(
//                               (index + 1).toString()), // Numéroter le ListTile
//                           title: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Montant: ${invoice['amount']}',
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                               Text(
//                                 'Référence: ${invoice['reference']}',
//                                 style: const TextStyle(),
//                               ),
//                             ],
//                           ),
//                           trailing: Text(
//                             invoice['ticket'] ?? '',
//                           ),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => DetailPage(
//                                   numero: invoice['reference'] ?? '',
//                                   date: formattedDate,
//                                   amount: invoice['amount'] ?? '',
//                                   taxateur: invoice['id'] ?? '',
//                                   parking: invoice['ticket'] ?? '',
//                                 ),
//                               ),
//                             );

//                             print(invoice);
//                           },
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }
