// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:taxaero/database/database_helper.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/app_text_large.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  _InvoiceListPageState createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  final LocalDatabase _localDatabase = LocalDatabase();
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    List<Map<String, dynamic>> invoices =
        await _localDatabase.getPendingInvoices();
    setState(() {
      _invoices = invoices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: AppTextLarge(text: 'Factures Local s: ${_invoices.length}'),
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
          ),
        ],
      ),
      body: _invoices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: Image.asset('assets/intro4.png'),
                  ),
                  AppText(text: 'Aucune donnée.')
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView.builder(
                itemCount: _invoices.length,
                itemBuilder: (context, index) {
                  final invoice = _invoices[index];
                  return Card(
                    child: ListTile(
                      leading: Text((index + 1).toString()),
                      title: AppText(
                        text: 'Parking: ${invoice['ticket']}',
                      ),
                      subtitle: AppText(
                        text: 'Montant: ${invoice['amount']}',
                      ),
                      trailing: AppText(
                        text: 'Référence: ${invoice['reference']}',
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
