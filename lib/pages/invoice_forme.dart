import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxaero/pages/detail_page.dart';
import 'package:taxaero/pages/intro/intro.dart';

class EditTaxFormPage extends StatefulWidget {
  const EditTaxFormPage({Key? key}) : super(key: key);

  @override
  _EditTaxFormPageState createState() => _EditTaxFormPageState();
}

class _EditTaxFormPageState extends State<EditTaxFormPage> {
  final _formKey = GlobalKey<FormState>();

  String ticket = '';
  String bill = '';
  String reference = '';
  late TextEditingController
      taxerController; // Utilisation d'un TextEditingController

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initValues();
    taxerController = TextEditingController(); // Initialisez le contrôleur ici
  }
//   Future<void> sendInvoice() async {
//   final url = Uri.parse('https://taxe.happook.com/api/invoices');
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String token = prefs.getString('token') ?? ''; // Assurez-vous que le token est enregistré dans les SharedPreferences
//   String userId = prefs.getString('id') ?? ''; // Récupération de l'ID de l'utilisateur connecté

//   try {
//     final response = await http.post(
//       url,
//       headers: <String, String>{
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token', // Utilisation du token pour l'authentification
//       },
//       body: jsonEncode(<String, String>{
//         'ticket': ticket,
//         'bill': bill,
//         'reference': reference,
//         'taxer': 'api/users/$userId', // Utilisation de l'ID de l'utilisateur connecté
//       }),
//     );

//     if (response.statusCode == 200) {
//       // Traitez la réponse ici si nécessaire
//       print('Invoice sent successfully');
//     } else {
//       // Gestion des erreurs
//       print('Failed to send invoice. Status code: ${response.statusCode}');
//       print('Reason: ${response.body}');
//     }
//   } catch (e) {
//     print('Error sending invoice: $e');
//   }
// }
  Future<void> sendInvoice(BuildContext context) async {
    final url = Uri.parse('https://taxe.happook.com/api/invoices');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String userId = prefs.getString('id') ?? '';

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'ticket': ticket,
          'bill': bill,
          'reference': reference,
          'taxer': 'api/users/$userId',
        }),
      );

      if (response.statusCode == 201) {
        // Récupérer les détails de la facture à partir de la réponse
        var responseData = jsonDecode(response.body);
        var invoiceId = responseData['id'];
        var ticket = responseData['ticket'];
        var bill = responseData['bill'];
        var reference = responseData['reference'];
        var taxer = responseData['taxer'];

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Invoice created successfully:'),
                  SizedBox(height: 10),
                  Text('ID: $invoiceId'),
                  Text('Ticket: $ticket'),
                  Text('Bill: $bill'),
                  Text('Reference: $reference'),
                  Text('Taxer: $taxer'),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                  'Failed to send invoice. Status code: ${response.statusCode}\nReason: ${response.body}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Error sending invoice: $e'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
    //  Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => DetailPage(
    //       numero: ticket,
    //       date: DateTime.now().toString(),
    //       montant: bill,
    //       taxateur: taxerController.text,
    //       parking: reference,
    //     ),
    //   ),
    // );
  }

  Future<void> initValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('id') ?? ''; // Récupération de l'ID
    setState(() {
      taxerController = TextEditingController(
          text: userId); // Initialisation du controller avec l'ID
    });
  }

  _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Efface toutes les données stockées
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Intro()),
    ); // Redirige vers la page d'introduction
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle Facture'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                buildFieldWithLabel('Ticket', ticket,
                    (value) => setState(() => ticket = value)),
                SizedBox(height: 20),
                buildFieldWithLabel(
                    'Bill', bill, (value) => setState(() => bill = value)),
                SizedBox(height: 20),
                buildFieldWithLabel('Reference', reference,
                    (value) => setState(() => reference = value)),
                SizedBox(height: 20),
                buildFieldWithLabel('Taxateur', taxerController.text,
                    (value) => taxerController.text = value),
                SizedBox(height: 40),
                Center(
                  child: isLoading
                      ? CircularProgressIndicator()
                      : CupertinoButton(
                          color: CupertinoColors.activeBlue,
                          onPressed: () {
                            print(_formKey.currentContext);
                            if (_formKey.currentState != null &&
                                _formKey.currentState!.validate()) {
                              print(_formKey.currentContext);
                              sendInvoice(context);
                            }
                          },
                          child: Text('Enregistrer'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFieldWithLabel(
      String label, String initialValue, Function(String) onChanged) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: CupertinoTextField(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            placeholder: 'Entrez $label',
            controller: TextEditingController(text: initialValue),
            onChanged: onChanged,
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
