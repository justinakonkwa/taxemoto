// ignore_for_file: use_super_parameters, prefer_const_constructors

import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'package:taxaero/widget/app_text_large.dart';
import 'package:taxaero/widget/constantes.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture'),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Affichage des informations de l'imprimante
                FutureBuilder(
                  future: _bindingPrinter(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      bool? printBinded = snapshot.data as bool?;
                      int paperSize = 0;
                      String serialNumber = "";
                      String printerVersion = "";

                      SunmiPrinter.paperSize().then((int size) {
                        paperSize = size;
                      });

                      SunmiPrinter.printerVersion().then((String version) {
                        printerVersion = version;
                      });

                      SunmiPrinter.serialNumber().then((String serial) {
                        serialNumber = serial;
                      });

                      return sizedbox;
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      CupertinoIcons.lock_shield,
                      size: 60,
                    ),
                    sizedbox2,
                    AppTextLarge(
                      text: 'TaxeMoto',
                      size: 30,
                    ),
                    sizedbox2,
                    const Icon(
                      Icons.directions_bike,
                      size: 60,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppTextLarge(
                  text: 'Taxe de Stationnement',
                ),
                AppTextLarge(
                  text: 'VILLE DE MOANDA',
                ),
                const Divider(thickness: 2),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Numéro',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Date',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Montant',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Taxateur',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Parking',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':01IX678-00086',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            ':25/03/2024 à 11h : 58',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            ':500 Fc',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            ':Sinsu',
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            ':Bayaka',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Text(
                  '********************************',
                  style: TextStyle(fontSize: 20),
                ),
                const Text(
                  '011 X67 800 600 243 P',
                  style: TextStyle(fontSize: 20),
                ),

                // detailRow('Numéro', ':01IX678-00086'),
                // detailRow('Date', '      :25/03/2024 à 11h : 58'),
                // detailRow('Montant', ':500 Fc'),
                // detailRow('Taxateur', ':Sinsu'),
                // detailRow('Parking', ':Bayaka'),
                // Spacer(),
                BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: '011 X67 800 600 243 P',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(30), // Set your desired border radius here
        ),
        backgroundColor: Colors.blue,
        onPressed: () => _printDocument(context),
        child: const Icon(Icons.print),
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(
            width: 10,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _printDocument(BuildContext context) async {
    try {
      // Vérification de la plateforme
      if (!Platform.isAndroid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'La fonction d\'impression n\'est pas disponible sur cette plateforme'),
          ),
        );
        return;
      }

      // Initialisation de l'imprimante
      bool? success = await SunmiPrinter.initPrinter();
      if (success != true) {
        throw Exception('Échec de l\'initialisation de l\'imprimante');
      }

      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);

      // Ajout de l'icône, du texte et de l'image
      await SunmiPrinter.printText(
        'TaxeMoto', // Icône de paiement

        style: SunmiStyle(bold: true, fontSize: SunmiFontSize.XL),
      );
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('Taxe de Stationnement');
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('VILLE DE MOANDA');
      await SunmiPrinter.line();

      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      await SunmiPrinter.printText('Numéro: 01IX678-00086');
      await SunmiPrinter.printText('');
      await SunmiPrinter.printText('Date: 25/03/2024 à 11h : 58');
      await SunmiPrinter.printText('');
      await SunmiPrinter.printText('Montant: 500 Fc');
      await SunmiPrinter.printText('');
      await SunmiPrinter.printText('Taxateur: Sinsu');
      await SunmiPrinter.printText('');
      await SunmiPrinter.printText('Parking: Bayaka');
      await SunmiPrinter.line();
      // Centrer le code QR
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      // Impression du code QR
      await SunmiPrinter.printQRCode(
        '011 X67 800 600 243 P',
      );
      await SunmiPrinter.printText('');
      await SunmiPrinter.printText('');
      await SunmiPrinter.printText('');

      // Affichage d'un message de réussite
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impression terminée avec succès',
          ),
        ),
      );
    } catch (e) {
      // Affichage d'un message d'erreur en cas d'échec de l'impression
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'impression : $e')),
      );
    }
  }

  Future<bool> _bindingPrinter() async {
    bool? result = await SunmiPrinter.bindingPrinter();
    return result ?? false;
  }
}


// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:taxaero/widget/app_text_large.dart';

// class DetailPage extends StatelessWidget {
//   final String numero;
//   final String date;
//   final String montant;
//   final String taxateur;
//   final String parking;

//   const DetailPage({
//     Key? key,
//     required this.numero,
//     required this.date,
//     required this.montant,
//     required this.taxateur,
//     required this.parking,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Facture'),
//       ),
//       body: SingleChildScrollView(
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                      Icon(
//                       CupertinoIcons.lock_shield,
//                       size: 60,
//                     ),
//                      AppTextLarge(
//                       text: 'TaxeMoto',
//                       size: 30,
//                     ),
//                     const Icon(
//                       Icons.directions_bike,
//                       size: 60,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                  AppTextLarge(
//                   text: 'Taxe de Stationnement',
//                 ),
//                  AppTextLarge(
//                   text: 'VILLE DE MOANDA',
//                 ),
//                 const Divider(thickness: 2),
//                 const SizedBox(height: 10),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   child: Row(
//                     children: [
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Numéro',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Text(
//                             'Date',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Text(
//                             'Montant',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Text(
//                             'Taxateur',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Text(
//                             'Parking',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                         ],
//                       ),
//                       SizedBox(
//                         width: 10,
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             ':$numero',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Text(
//                             ':$date',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Text(
//                             ':$montant',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Text(
//                             ':$taxateur',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                           Text(
//                             ':$parking',
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Text(
//                   '********************************',
//                   style: TextStyle(fontSize: 20),
//                 ),
//                 const Text(
//                   '011 X67 800 600 243 P',
//                   style: TextStyle(fontSize: 20),
//                 ),
//                 const SizedBox(height: 50),
//               ],
//             ),
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(30),
//         ),
//         backgroundColor: Colors.blue,
//         onPressed: () => _printDocument(context),
//         child: const Icon(Icons.print),
//       ),
//     );
//   }

//   Future<void> _printDocument(BuildContext context) async {
//     // Votre logique d'impression
//   }
// }
