// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, use_super_parameters

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // Importez dart:math
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxaero/pages/detail_page.dart';
import 'package:intl/intl.dart';
import 'package:taxaero/widget/app_text.dart';

class EditTaxFormPage extends StatefulWidget {
  const EditTaxFormPage({Key? key}) : super(key: key);

  @override
  _EditTaxFormPageState createState() => _EditTaxFormPageState();
}

class _EditTaxFormPageState extends State<EditTaxFormPage> {
  final _formKey = GlobalKey<FormState>();

  String ticket = '';
  String bill = '';
  late TextEditingController referenceController;
  late TextEditingController taxerController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    referenceController = TextEditingController();
    taxerController = TextEditingController();
    initValues();
  }

  // Fonction pour générer un code hexadécimal aléatoire
  String generateHexCode(int length) {
    const chars = '0123 45678 9ABCDEF';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> sendInvoice(BuildContext context) async {
    final url = Uri.parse('https://taxe.happook.com/api/invoices');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String userId = prefs.getString('id') ?? '';

    // Générez un code hexadécimal de 10 caractères pour la référence
    String reference = referenceController.text;

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

        Navigator.of(context).pop();
        // Navigate to the detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              numero: reference,
              date: DateFormat('yyyy-MM-dd HH:mm').format(
                DateTime.now(),
              ),
              montant: bill,
              taxateur: taxerController.text,
              parking: ticket,
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(
                  'Failed to send invoice. Status code: ${response.statusCode}\nReason: ${response.body}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
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
            title: const Text('Error'),
            content: Text('Error sending invoice: $e'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> initValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('id') ?? ''; // Récupération de l'ID

    // Générez un code hexadécimal de 10 caractères pour la référence
    String reference = generateHexCode(10);

    setState(() {
      taxerController.text = userId; // Initialisation du contrôleur avec l'ID
      referenceController.text =
          reference; // Initialisation du contrôleur avec le code hexadécimal
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Facture'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                buildFieldWithLabels('Numero', referenceController.text,
                    (value) => setState(() => ticket)),
                const SizedBox(height: 20),
                buildFieldWithLabel(
                    'Montant',
                    bill,
                    (value) => setState(
                          () => bill = value,
                        ),
                    TextInputType.number),
                const SizedBox(height: 20),
                buildFieldWithLabel('Parking', ticket,
                    (value) => ticket = value, TextInputType.phone),
                const SizedBox(height: 20),
                buildFieldWithLabel(
                    'Taxateur',
                    taxerController.text,
                    (value) => taxerController.text = value,
                    TextInputType.phone),
                const SizedBox(height: 40),
                Center(
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : CupertinoButton(
                          color: CupertinoColors.activeBlue,
                          onPressed: () {
                            if (bill != '' && ticket != '') {
                              if (_formKey.currentState != null &&
                                  _formKey.currentState!.validate()) {
                                sendInvoice(context);
                              }
                            } else {
                              _showErrorDialog(
                                  'Échec d\'enregistrement. completez toutes les cases et réessayez.',
                                  context);
                            }
                          },
                          child: const Text('Enregistrer'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _showErrorDialog(String message, BuildContext context) {
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
      String label, String initialValue, Function(String) onChanged, type) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: CupertinoTextField(
            keyboardType: type,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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

  Widget buildFieldWithLabels(
      String label, String initialValue, Function(String) onChanged) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 10),
            height: 40,
            // ignore: sort_child_properties_last
            child: Text(
              initialValue,
            ),
            decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
