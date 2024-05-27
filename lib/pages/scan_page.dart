// // ignore_for_file: use_build_context_synchronously

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'package:taxaero/widget/app_text.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ScanPage extends StatefulWidget {
//   const ScanPage({super.key});

//   @override
//   State<StatefulWidget> createState() => _ScanPageState();
// }

// class _ScanPageState extends State<ScanPage> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;

//   @override
//   void reassemble() {
//     super.reassemble();
//     if (Platform.isAndroid) {
//       controller!.pauseCamera();
//     }

//     controller!.resumeCamera();
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;
//     controller.scannedDataStream.listen((scanData) {
//       controller.pauseCamera();
//       processQRCode(scanData.code);
//     });
//   }

//   // Gestion du résultat du scan
//   void processQRCode(String? result) async {
//     if (result != null && await canLaunch(result)) {
//       await launch(result);
//     } else {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: AppText(text: 'Résultat du Scan'),
//           content: Text('Code QR : $result'),
//           actions: <Widget>[
//             TextButton(
//               child: AppText(text: 'OK'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//           ],
//         ),
//       );
//     }
//     Navigator.pop(
//         context); // Pour retourner à la page précédente après traitement
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0.0,
//         automaticallyImplyLeading: false,
//         centerTitle: true,
//         title: AppText(text: 'Scanner Qr code'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             flex: 5,
//             child: QRView(
//               key: qrKey,
//               onQRViewCreated: _onQRViewCreated,
//               overlay: QrScannerOverlayShape(
//                 borderColor: Colors.blue,
//                 borderRadius: 10,
//                 borderLength: 30,
//                 borderWidth: 10,
//                 cutOutSize: MediaQuery.of(context).size.width * 0.8,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Center(
//               child: AppText(text: 'Scannez un code QR'),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:http/http.dart' as http;


class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<StatefulWidget> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      controller.pauseCamera();
      processQRCode(scanData.code);
    });
  }

  // Gestion du résultat du scan
  void processQRCode(String? result) async {
    if (result != null) {
      print('QR Code result: $result');
      try {
        // Utilisez la méthode fetchInvoiceByNumero pour récupérer les informations de la facture par numéro
        Map<String, dynamic>? invoiceData = await fetchInvoiceByNumero(result);
        if (invoiceData != null) {
          // Affichez les informations de la facture dans votre application
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: AppText(text: 'Détails de la facture'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppText(text: 'Numéro: $result'),
                  AppText(text: 'Ticket: ${invoiceData['ticket']}'),
                  AppText(text: 'Montant: ${invoiceData['bill']} Fc'), // Montant
                  AppText(text: 'Référence: ${invoiceData['reference']}'), // Référence
                  AppText(text: 'Date: ${invoiceData['date']}'), // Date
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: AppText(text: 'OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    controller!.resumeCamera();
                  },
                ),
              ],
            ),
          );
        } else {
          // Facture non trouvée
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: AppText(text: 'Erreur'),
              content: AppText(text: 'Aucune facture trouvée pour le numéro $result.'),
              actions: <Widget>[
                TextButton(
                  child: AppText(text: 'OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    controller!.resumeCamera();
                  },
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print('Erreur lors de la récupération des informations de la facture: $e');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: AppText(text: 'Erreur'),
            content: AppText(text: 'Impossible de récupérer les informations de la facture.'),
            actions: <Widget>[
              TextButton(
                child: AppText(text: 'OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  controller!.resumeCamera();
                },
              ),
            ],
          ),
        );
      }
    } else {
      // Code QR vide
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: AppText(text: 'Résultat du Scan'),
          content: AppText(text: 'Aucun code QR trouvé'),
          actions: <Widget>[
            TextButton(
              child: AppText(text: 'OK'),
              onPressed: () {
                Navigator.of(context).pop();
                controller!.resumeCamera();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: AppText(text: 'Scanner QR code'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
         
Expanded(
  flex: 1,
  child: Center(
    child: AppText(text: 'Scannez un code QR'),
  ),
)
],
),
);
}

static Future<Map<String, dynamic>?> fetchInvoiceByNumero(String numero) async {
final url = Uri.parse('https://taxe.happook.com/api/invoices?numero=$numero');

print('Fetching invoice with numero: $numero and URL: $url');

try {
final response = await http.get(url);

print('Status code: ${response.statusCode}');
print('Response body: ${response.body}');

if (response.statusCode == 200) {
  List<dynamic> responseData = jsonDecode(response.body)['hydra:member'];
  if (responseData.isNotEmpty) {
    Map<String, dynamic> invoiceData = responseData.first;
    return {
      'numero': invoiceData['numero'],
      'ticket': invoiceData['ticket'],
      'bill': invoiceData['bill'],
      'reference': invoiceData['reference'],
      'date': invoiceData['date'],
    };
  }
} else {
  throw Exception('Échec de la requête: ${response.statusCode}');
}
} catch (e) {
print('Erreur lors de la récupération des factures: $e');
throw Exception('Erreur lors de la récupération des factures: $e');
}
return null;
}
}
