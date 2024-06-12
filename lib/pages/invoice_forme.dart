// ignore_for_file: prefer_const_constructors

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxaero/connectivity.dart';
import 'package:taxaero/database/database_helper.dart';
import 'package:taxaero/pages/detail_page.dart';
import 'package:intl/intl.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/app_text_large.dart';
import 'package:taxaero/widget/bouton_next.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({Key? key}) : super(key: key);

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _formKey = GlobalKey<FormState>();

  String ticket = '';
  int amount = 0;
  late TextEditingController referenceController;
  late TextEditingController taxerController;
  late TextEditingController ticketController;
  late TextEditingController amountController;

  bool isLoading = false;
  final ConnectivityService _connectivityService = ConnectivityService();
  // final InvoiceSyncService _invoiceSyncService = InvoiceSyncService();

  @override
  void initState() {
    super.initState();
    referenceController = TextEditingController();
    taxerController = TextEditingController();
    ticketController = TextEditingController();
    amountController = TextEditingController();
    initValues();
    _connectivityService.connectivityStream.listen((connectivityResult) {
      if (connectivityResult.isNotEmpty &&
          connectivityResult[0] != ConnectivityResult.none) {
        // _invoiceSyncService.syncPendingInvoices();
      }
    });
  }

  @override
  void dispose() {
    referenceController.dispose();
    taxerController.dispose();
    ticketController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String generateHexCode(int length) {
    const chars = '0123456789AbCdEfGhIjKlMNoPqRsTuVwXyZ ';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> sendInvoice(BuildContext context) async {
    final url = Uri.parse('https://taxe.happook.com/api/invoices');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String userId = prefs.getString('id') ?? '';

    String reference = referenceController.text;
    String currentDateTime =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'ticket': ticket,
          'amount': amount,
          'reference': reference,
          'taxer': 'api/users/$userId',
          'date_sold': currentDateTime,
        }),
      );

      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        var ticket = responseData['ticket'];
        var amount = responseData['amount'];
        var reference = responseData['reference'];

        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              numero: reference,
              date: currentDateTime,
              amount: amount,
              taxateur: taxerController.text,
              parking: ticket,
            ),
          ),
        );
      } else {
        await _saveInvoiceLocally(
            ticket, amount, reference, userId, currentDateTime, token);
        _showErrorDialog(
            'Facture enregistrée localement. Status code: ${response.statusCode}\nReason: ${response.body}',
            context);
      }
    } catch (e) {
      await _saveInvoiceLocally(
          ticket, amount, reference, userId, currentDateTime, token);
      _showErrorDialog(
          'Erreur lors de l\'envoi de la facture. Enregistrée localement: $e',
          context);
    }
  }

  Future<void> _saveInvoiceLocally(String ticket, int amount, String reference,
      String userId, String dateSold, String token) async {
    final localDatabase = LocalDatabase();
    await localDatabase.insertInvoice({
      'ticket': ticket,
      'amount': amount,
      'reference': reference,
      'userId': userId,
      'date_sold': dateSold,
      'token': token
    });

    // Après avoir enregistré localement, naviguer vers la page de détail
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          numero: reference,
          date: dateSold,
          amount: amount,
          taxateur: taxerController.text,
          parking: ticket,
        ),
      ),
    );
  }

  Future<void> initValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('id') ?? '';

    String reference = generateHexCode(10);

    setState(() {
      taxerController.text = userId;
      referenceController.text = reference;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Container(
                margin: const EdgeInsets.all(5.0),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Theme.of(context).colorScheme.primary,
                ),

            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.clear,
                color: Colors.red,
              ),
            ),
          )
        ],
        backgroundColor: Colors.transparent,
        title: AppTextLarge(text: 'Nouveau Ticket'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: 'Numero:',
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 10),
                      width: MediaQuery.of(context).size.width * 0.60,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AppTextLarge(
                        text: referenceController.text,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                // buildFieldWithLabel(
                //     'Numero', referenceController, TextInputType.none),
                const SizedBox(height: 20),
                buildFieldWithLabel(
                    'Montant', amountController, TextInputType.number),
                const SizedBox(height: 20),
                buildFieldWithLabel(
                    'Parking', ticketController, TextInputType.text),
                const SizedBox(height: 50),
                Center(
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : NextButton(
                            onTap: () {
                              if (amountController.text.isNotEmpty &&
                                  ticketController.text.isNotEmpty) {
                                if (_formKey.currentState != null &&
                                    _formKey.currentState!.validate()) {
                                  setState(() {
                                    amount = int.parse(amountController.text);
                                    ticket = ticketController.text;
                                  });
                                  sendInvoice(context);
                                }
                              } else {
                                _showErrorDialog(
                                    'Échec d\'enregistrement. Completez toutes les cases et réessayez.',
                                    context);
                              }
                            },
                            child: AppTextLarge(
                              text: 'Enregistrer',
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText(
          text: 'Erreur',
          textAlign: TextAlign.center,
        ),
        content: AppText(
          text: message,
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            child: AppText(
              text: 'OK',
              textAlign: TextAlign.center,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  Widget buildFieldWithLabel(
      String label, TextEditingController controller, TextInputType type) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: AppText(
            text: '$label:',
          ),
        ),
        Expanded(
          flex: 2,
          child: CupertinoTextField(
            keyboardType: type,
            style: const TextStyle(
              fontFamily: 'Montserrat',
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            placeholder: 'Entrez $label',
            placeholderStyle: TextStyle(
                fontFamily: 'Montserrat',
                color: Theme.of(context).colorScheme.secondary),
            controller: controller,
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey, width: 1.0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}







// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taxaero/pages/detail_page.dart';
// import 'package:intl/intl.dart';
// import 'package:taxaero/widget/app_text.dart';

// class EditTaxFormPage extends StatefulWidget {
//   const EditTaxFormPage({Key? key}) : super(key: key);

//   @override
//   _EditTaxFormPageState createState() => _EditTaxFormPageState();
// }

// class _EditTaxFormPageState extends State<EditTaxFormPage> {
//   final _formKey = GlobalKey<FormState>();

//   String ticket = '';
//   int amount = 0; // Changement ici
//   late TextEditingController referenceController;
//   late TextEditingController taxerController;
//   late TextEditingController ticketController;
//   late TextEditingController amountController; // Changement ici

//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     referenceController = TextEditingController();
//     taxerController = TextEditingController();
//     ticketController = TextEditingController();
//     amountController = TextEditingController(); // Changement ici
//     initValues();
//   }

//   @override
//   void dispose() {
//     referenceController.dispose();
//     taxerController.dispose();
//     ticketController.dispose();
//     amountController.dispose(); // Changement ici
//     super.dispose();
//   }

//   String generateHexCode(int length) {
//     const chars = '0123456789ABCDEF';
//     final rand = Random();
//     return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
//         .join();
//   }

//   Future<void> sendInvoice(BuildContext context) async {
//     final url = Uri.parse('https://taxe.happook.com/api/invoices');
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String token = prefs.getString('token') ?? '';
//     String userId = prefs.getString('id') ?? '';

//     String reference = referenceController.text;
//     String currentDateTime =
//         DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

//     try {
//       final response = await http.post(
//         url,
//         headers: <String, String>{
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(<String, dynamic>{
//           'ticket': ticket,
//           'amount': amount, // Envoyer amount comme un int
//           'reference': reference,
//           'taxer': 'api/users/$userId',
//           'date_sold': currentDateTime,
//         }),
//       );

//       if (response.statusCode == 201) {
//         var responseData = jsonDecode(response.body);
//         var ticket = responseData['ticket'];
//         var amount = responseData['amount']; // Garder amount comme un int
//         var reference = responseData['reference'];

//         Navigator.of(context).pop();
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DetailPage(
//               numero: reference,
//               date: currentDateTime,
//               amount: amount, // Garder amount comme un int
//               taxateur: taxerController.text,
//               parking: ticket,
//             ),
//           ),
//         );
//       } else {
//         _showErrorDialog(
//             'Failed to send invoice. Status code: ${response.statusCode}\nReason: ${response.body}',
//             context);
//         print(
//           'Failed to send invoice. Status code: ${response.statusCode}\nReason: ${response.body}',
//         );
//       }
//     } catch (e) {
//       _showErrorDialog('Error sending invoice: $e', context);
//     }
//   }

//   Future<void> initValues() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String userId = prefs.getString('id') ?? '';

//     String reference = generateHexCode(10);

//     setState(() {
//       taxerController.text = userId;
//       referenceController.text = reference;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         actions: [
//           IconButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               icon: const Icon(
//                 Icons.clear,
//                 color: Colors.red,
//               ),)
//         ],
//         backgroundColor: Colors.transparent,
//         title: const Text('Nouvelle Facture'),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 buildFieldWithLabel(
//                     'Numero', referenceController, TextInputType.none),
//                 const SizedBox(height: 20),
//                 buildFieldWithLabel(
//                     'Montant', amountController, TextInputType.number), // Changement ici
//                 const SizedBox(height: 20),
//                 buildFieldWithLabel(
//                     'Parking', ticketController, TextInputType.text),
//                 const SizedBox(height: 20),
//                 // buildFieldWithLabel(
//                 //     'Taxateur', taxerController, TextInputType.none),
//                 const SizedBox(height: 50),
//                 Center(
//                   child: isLoading
//                       ? const CircularProgressIndicator()
//                       : CupertinoButton(
//                           color:  Colors.blue.shade400,
//                           onPressed: () {
//                             if (amountController.text.isNotEmpty && // Changement ici
//                                 ticketController.text.isNotEmpty) {
//                               if (_formKey.currentState != null &&
//                                   _formKey.currentState!.validate()) {
//                                 setState(() {
//                                   amount = int.parse(amountController.text); // Changement ici
//                                   ticket = ticketController.text;
//                                 });
//                                 sendInvoice(context);
//                               }
//                             } else {
//                               _showErrorDialog(
//                                   'Échec d\'enregistrement. Completez toutes les cases et réessayez.',
//                                   context);
//                             }
//                           },
//                           child: const Text('Enregistrer'),
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showErrorDialog(String message, BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: AppText(
//           text: 'Erreur',
//           textAlign: TextAlign.center,
//         ),
//         content: AppText(
//           text: message,
//           textAlign: TextAlign.center,
//         ),
//         actions: <Widget>[
//           TextButton(
//             child: AppText(
//               text: 'OK',
//               textAlign: TextAlign.center,
//             ),
//             onPressed: () {
//               Navigator.of(ctx).pop();
//             },
//           )
//         ],
//       ),
//     );
//   }

//   Widget buildFieldWithLabel(
//       String label, TextEditingController controller, TextInputType type) {
//     return Row(
//       children: <Widget>[
//         Expanded(
//           flex: 1,
//           child: Text(
//             '$label:',
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         ),
//         Expanded(
//           flex: 2,
//           child: CupertinoTextField(
//             keyboardType: type,
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//             placeholder: 'Entrez $label',
//             controller: controller,
//             decoration: BoxDecoration(
//               border: Border.all(color: CupertinoColors.systemGrey, width: 1.0),
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
