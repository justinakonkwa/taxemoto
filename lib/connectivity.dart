import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:taxaero/database/database_helper.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;
}

class InvoiceSyncService {
  final LocalDatabase _localDatabase = LocalDatabase();

  Future<void> syncPendingInvoices() async {
    List<Map<String, dynamic>> invoices =
        await _localDatabase.getPendingInvoices();
    Map<String, Map<String, dynamic>> uniqueInvoices =
        {}; // Pour garder une seule facture par référence

    // Filtrer et garder une seule facture par référence
    for (var invoice in invoices) {
      if (!uniqueInvoices.containsKey(invoice['reference'])) {
        uniqueInvoices[invoice['reference']] = invoice;
      }
    }

    // Tenter de synchroniser les factures uniques
    for (var invoice in uniqueInvoices.values) {
      // Vérifier si la facture a déjà été synchronisée
      if (invoice['is_synced'] != null && invoice['is_synced'] == 1) {
        continue; // Passer à la prochaine facture si celle-ci est déjà traitée
      }

      try {
        final responseCheck = await http.get(
          Uri.parse(
              'https://taxe.happook.com/api/invoices/${invoice['reference']}'),
          headers: <String, String>{
            'Authorization': 'Bearer ${invoice['token']}',
          },
        );

        // Synchroniser seulement si la facture n'existe pas déjà sur l'API
        if (responseCheck.statusCode == 404) {
          final response = await http.post(
            Uri.parse('https://taxe.happook.com/api/invoices'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${invoice['token']}',
            },
            body: jsonEncode(<String, dynamic>{
              'ticket': invoice['ticket'],
              'amount': invoice['amount'],
              'reference': invoice['reference'],
              'taxer': 'api/users/${invoice['userId']}',
              'date_sold': invoice['date_sold'],
            }),
          );

          if (response.statusCode == 201) {
            // Marquer la facture comme synchronisée
            await _localDatabase.updateInvoiceAsSynced(invoice['id']);
          } else {
            print(
                'Échec de la synchronisation de la facture. Code de statut : ${response.statusCode}');
          }
        } else if (responseCheck.statusCode == 200) {
          // La facture existe déjà sur l'API, marquer comme synchronisée localement
          await _localDatabase.updateInvoiceAsSynced(invoice['id']);
        }
      } catch (e) {
        print('Erreur lors de la synchronisation de la facture : $e');
      }
    }

    // Supprimer les factures dupliquées après synchronisation
    for (var invoice in invoices) {
      if (!uniqueInvoices.containsKey(invoice['reference']) ||
          (invoice['is_synced'] != null && invoice['is_synced'] == 1)) {
        await _localDatabase.deleteInvoice(invoice['id']);
      }
    }
  }
}






