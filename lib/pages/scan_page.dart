// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (result != null && await canLaunch(result)) {
      await launch(result);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: AppText(text: 'Résultat du Scan'),
          content: Text('Code QR : $result'),
          actions: <Widget>[
            TextButton(
              child: AppText(text: 'OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
    Navigator.pop(
        context); // Pour retourner à la page précédente après traitement
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
}
