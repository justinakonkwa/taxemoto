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
      // Utilisez la méthode fetchInvoice pour récupérer les informations de la facture
      try {
        Map<String, dynamic> invoiceData = await fetchInvoice(result);
        // Affichez les informations de la facture dans votre application
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: AppText(text: 'Détails de la facture'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppText(text: 'Numéro: ${invoiceData['numero']}'),
                AppText(text: 'Date: ${invoiceData['date']}'),
                AppText(text: 'Montant: ${invoiceData['montant']}'),
                AppText(text: 'Taxateur: ${invoiceData['taxateur']}'),
                AppText(text: 'Parking: ${invoiceData['parking']}'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: AppText(text: 'OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } catch (e) {
        // Gérez les erreurs de récupération de la facture
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: AppText(text: 'Erreur'),
            content: AppText(text: 'Impossible de récupérer les informations de la facture'),
            actions: <Widget>[
              TextButton(
                child: AppText(text: 'OK'),
                onPressed: () => Navigator.of(context).pop(),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
    Navigator.pop(context); // Pour retourner à la page précédente après traitement
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: AppText(text: 'Scanner Qr code'),
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
  static Future<Map<String, dynamic>> fetchInvoice(String codeQR) async {
    final url = Uri.parse('https://taxe.happook.com/api/invoices/$codeQR'); // URL de votre API pour récupérer les détails de la facture

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Analysez les données JSON de la réponse pour extraire les informations sur la facture
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'numero': responseData['numero'],
          'date': responseData['date'],
          'montant': responseData['montant'],
          'taxateur': responseData['taxateur'],
          'parking': responseData['parking'],
        };
      } else {
        // Gérez les erreurs de requête HTTP
        throw Exception('Échec de la requête: ${response.statusCode}');
      }
    } catch (e) {
      // Gérez les erreurs d'exception
      throw Exception('Erreur lors de la récupération des données de la facture: $e');
    }
  }
}

