import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
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
  int amount = 0; // Changement ici
  late TextEditingController referenceController;
  late TextEditingController taxerController;
  late TextEditingController ticketController;
  late TextEditingController amountController; // Changement ici

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    referenceController = TextEditingController();
    taxerController = TextEditingController();
    ticketController = TextEditingController();
    amountController = TextEditingController(); // Changement ici
    initValues();
  }

  @override
  void dispose() {
    referenceController.dispose();
    taxerController.dispose();
    ticketController.dispose();
    amountController.dispose(); // Changement ici
    super.dispose();
  }

  String generateHexCode(int length) {
    const chars = '0123456789ABCDEF';
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
          'amount': amount, // Envoyer amount comme un int
          'reference': reference,
          'taxer': 'api/users/$userId',
          'date_sold': currentDateTime,
        }),
      );

      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        var ticket = responseData['ticket'];
        var amount = responseData['amount']; // Garder amount comme un int
        var reference = responseData['reference'];

        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              numero: reference,
              date: currentDateTime,
              amount: amount, // Garder amount comme un int
              taxateur: taxerController.text,
              parking: ticket,
            ),
          ),
        );
      } else {
        _showErrorDialog(
            'Failed to send invoice. Status code: ${response.statusCode}\nReason: ${response.body}',
            context);
        print(
          'Failed to send invoice. Status code: ${response.statusCode}\nReason: ${response.body}',
        );
      }
    } catch (e) {
      _showErrorDialog('Error sending invoice: $e', context);
    }
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
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.clear,
                color: Colors.red,
              ),)
        ],
        backgroundColor: Colors.transparent,
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
                buildFieldWithLabel(
                    'Numero', referenceController, TextInputType.none),
                const SizedBox(height: 20),
                buildFieldWithLabel(
                    'Montant', amountController, TextInputType.number), // Changement ici
                const SizedBox(height: 20),
                buildFieldWithLabel(
                    'Parking', ticketController, TextInputType.text),
                const SizedBox(height: 20),
                // buildFieldWithLabel(
                //     'Taxateur', taxerController, TextInputType.none),
                const SizedBox(height: 50),
                Center(
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : CupertinoButton(
                          color:  Colors.blue.shade400,
                          onPressed: () {
                            if (amountController.text.isNotEmpty && // Changement ici
                                ticketController.text.isNotEmpty) {
                              if (_formKey.currentState != null &&
                                  _formKey.currentState!.validate()) {
                                setState(() {
                                  amount = int.parse(amountController.text); // Changement ici
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
