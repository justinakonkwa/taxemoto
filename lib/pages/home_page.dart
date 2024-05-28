// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:async';

// import 'package:taxaero/pages/invoice_forme.dart';
// import 'package:taxaero/pages/user_page.dart';
// import 'package:taxaero/widget/app_text.dart';
// import 'package:taxaero/widget/app_text_large.dart';
// import 'package:taxaero/widget/constantes.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   late SharedPreferences prefs;
//   final _totalBillTodayController = StreamController<double>.broadcast();
//   final _numberOfInvoicesTodayController = StreamController<int>.broadcast();
//   late List<SalesData> salesDataList = [];
//   double totalBillYesterday = 0.0;
//   int numberOfInvoicesYesterday = 0;
//   double totalBillLastMonth = 0.0;
//   int numberOfInvoicesLastMonth = 0;

// @override
// void initState() {
//   super.initState();
//   initSharedPreferences();
//   fetchData();
//   scheduleEndOfDayTask();
//   Timer.periodic(const Duration(seconds: 10), (timer) {
//     fetchData();
//   });
// }

//   @override
//   void dispose() {
//     _totalBillTodayController.close();
//     _numberOfInvoicesTodayController.close();
//     super.dispose();
//   }

// void initSharedPreferences() async {
//   prefs = await SharedPreferences.getInstance();
//   setState(() {
//     totalBillYesterday = prefs.getDouble('totalBillYesterday') ?? 0.0;
//     numberOfInvoicesYesterday = prefs.getInt('numberOfInvoicesYesterday') ?? 0;
//     totalBillLastMonth = prefs.getDouble('totalBillLastMonth') ?? 0.0;
//     numberOfInvoicesLastMonth = prefs.getInt('numberOfInvoicesLastMonth') ?? 0;
//     print('Retrieved totalBillYesterday: $totalBillYesterday');
//     print('Retrieved numberOfInvoicesYesterday: $numberOfInvoicesYesterday');
//     print('Retrieved totalBillLastMonth: $totalBillLastMonth');
//     print('Retrieved numberOfInvoicesLastMonth: $numberOfInvoicesLastMonth');
//   });
// }

// void fetchData() async {
//   if (!_totalBillTodayController.isClosed && !_numberOfInvoicesTodayController.isClosed) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);

//     final url = Uri.parse('https://taxe.happook.com/api/invoices');
//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final jsonData = json.decode(response.body);
//       final List<dynamic> invoices = jsonData['hydra:member'];

//       final todayInvoices = invoices.where((invoice) {
//         final invoiceDateStr = invoice['createdAt'];
//         if (invoiceDateStr != null) {
//           final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
//           return invoiceDate.year == today.year && invoiceDate.month == today.month && invoiceDate.day == today.day;
//         }
//         return false;
//       }).toList();

//       final numberOfInvoicesToday = todayInvoices.length;
//       final totalBillToday = todayInvoices.fold(0.0, (sum, invoice) {
//         final bill = invoice['bill'];
//         if (bill != null && double.tryParse(bill) != null) {
//           return sum + double.parse(bill);
//         }
//         return sum;
//       }).toDouble();

//       if (!_totalBillTodayController.isClosed) {
//         _totalBillTodayController.add(totalBillToday);
//       }
//       if (!_numberOfInvoicesTodayController.isClosed) {
//         _numberOfInvoicesTodayController.add(numberOfInvoicesToday);
//       }

//       updateSalesDataList(invoices);

//       // Log today's data
//       print('Nombre de factures vendues aujourd\'hui : $numberOfInvoicesToday');
//       print('Total des montants vendus aujourd\'hui : $totalBillToday');
//     } else {
//       print('Failed to fetch data. Status code: ${response.statusCode}');
//     }
//   }
// }

// void updateSalesDataList(List<dynamic> invoices) {
//   salesDataList = [];

//   salesDataList.add(SalesData('Lun', getTotalSalesForDay(invoices, DateTime.monday)));
//   salesDataList.add(SalesData('Mar', getTotalSalesForDay(invoices, DateTime.tuesday)));
//   salesDataList.add(SalesData('Mer', getTotalSalesForDay(invoices, DateTime.wednesday)));
//   salesDataList.add(SalesData('Jeu', getTotalSalesForDay(invoices, DateTime.thursday)));
//   salesDataList.add(SalesData('Ven', getTotalSalesForDay(invoices, DateTime.friday)));
//   salesDataList.add(SalesData('Sam', getTotalSalesForDay(invoices, DateTime.saturday)));
//   salesDataList.add(SalesData('Dim', getTotalSalesForDay(invoices, DateTime.sunday)));

//   setState(() {
//     print('Sales data updated');
//     salesDataList.forEach((data) {
//       print('${data.year}: ${data.sales}');
//     });
//   });
// }

//   double getTotalSalesForDay(List<dynamic> invoices, int dayOfWeek) {
//     final salesForDay = invoices.where((invoice) {
//       final invoiceDateStr = invoice['createdAt'];
//       if (invoiceDateStr != null) {
//         final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
//         return invoiceDate.weekday == dayOfWeek;
//       }
//       return false;
//     }).toList();

//     return salesForDay.fold(0.0, (sum, invoice) {
//       final bill = invoice['bill'];
//       if (bill != null && double.tryParse(bill) != null) {
//         return sum + double.parse(bill);
//       }
//       return sum;
//     });
//   }

// void storeYesterdayData(double totalBill, int numberOfInvoices) async {
//   prefs = await SharedPreferences.getInstance();
//   await prefs.setDouble('totalBillYesterday', totalBill);
//   await prefs.setInt('numberOfInvoicesYesterday', numberOfInvoices);
//   print('Storing totalBillYesterday: $totalBill');
//   print('Storing numberOfInvoicesYesterday: $numberOfInvoices');
// }

// void scheduleEndOfDayTask() {
//   final now = DateTime.now();
//   final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

//   Timer(Duration(milliseconds: endOfDay.millisecondsSinceEpoch - now.millisecondsSinceEpoch), () async {
//     final totalBillToday = await _totalBillTodayController.stream.first;
//     final numberOfInvoicesToday = await _numberOfInvoicesTodayController.stream.first;
//     storeYesterdayData(totalBillToday, numberOfInvoicesToday);
//     print('End of day task executed');
//   });
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 Row(
//                   children: [
//                     AppTextLarge(
//                       text: 'Taxe Moto',
//                       size: 40,
//                     ),
//                     const Spacer(),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const UserPage(),
//                           ),
//                         );
//                       },
//                       child: Card(
//                         child: Container(
//                           height: 50,
//                           width: 50,
//                           child: IconButton(
//                             onPressed: () {
//                               showModalBottomSheet(
//                                 backgroundColor: Colors.transparent,
//                                 useSafeArea: true,
//                                 context: context,
//                                 builder: (context) {
//                                   return Container(
//                                     decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(20),
//                                         color: Colors.white),
//                                     child: const UserPage(),
//                                   );
//                                 },
//                               );
//                             },
//                             icon: Icon(Icons.person),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 StreamBuilder<double>(
//                   stream: _totalBillTodayController.stream,
//                   builder: (context, snapshot) {
//                     if (snapshot.hasData) {
//                       return Padding(
//                         padding: const EdgeInsets.only(left: 15.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(text: 'TOTAL VENTE AUJOURD\'HUI'),
//                             AppTextLarge(
//                               text: 'Fc ${snapshot.data!.toStringAsFixed(2)}',
//                               size: 20,
//                             ),
//                           ],
//                         ),
//                       );
//                     } else {
//                       return const Text('chargement ...');
//                     }
//                   },
//                 ),
//                 sizedbox,
//                 StreamBuilder<int>(
//                   stream: _numberOfInvoicesTodayController.stream,
//                   builder: (context, snapshot) {
//                     if (snapshot.hasData) {
//                       return Padding(
//                         padding: const EdgeInsets.only(left: 15.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             AppText(
//                               text: 'TICKETS VENDU',
//                               size: 18,
//                             ),
//                             AppTextLarge(
//                               text: '${snapshot.data}',
//                               size: 18,
//                             ),
//                           ],
//                         ),
//                       );
//                     } else {
//                       return const Text('chargement ...');
//                     }
//                   },
//                 ),
//                 sizedbox,
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   height: 300.0,
//                   decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       color: Colors.blue.shade100),
//                   child: SfCartesianChart(
//                     primaryXAxis: const CategoryAxis(),
//                     series: <ColumnSeries<SalesData, String>>[
//                       ColumnSeries<SalesData, String>(
//                         dataSource: salesDataList,
//                         xValueMapper: (SalesData sales, _) => sales.year,
//                         yValueMapper: (SalesData sales, _) => sales.sales,
//                         isTrackVisible: true,
//                         borderRadius: BorderRadius.circular(10),
//                       )
//                     ],
//                   ),
//                 ),
//                 sizedbox,
//                 Container(
//                   margin: const EdgeInsets.only(left: 15.0),
//                   child: AppText(text: 'STATISTIQUE'),
//                 ),

//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     _buildStatContainer(context, 'Hier:', totalBillYesterday,
//                         '$numberOfInvoicesYesterday Tck'),
//                     _buildStatContainer(context, 'Mois Passé:',
//                         totalBillLastMonth, '$numberOfInvoicesLastMonth Tck'),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         shape: RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(30), // Set your desired border radius here
//         ),
//         onPressed: () {
//           showModalBottomSheet(
//             backgroundColor: Colors.transparent,
//             useSafeArea: true,
//             context: context,
//             builder: (context) {
//               return Container(
//                 decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(20),
//                     color: Colors.white),
//                 child: const EditTaxFormPage(),
//               );
//             },
//           );
//         },
//         child: const Icon(Icons.note_add),
//       ),
//     );
//   }
// Widget _buildStatContainer(
//     BuildContext context, String period, double sales, String billets) {
//   print('$period - Sales: $sales, Billets: $billets');

//   return Container(
//     height: 100,
//     width: MediaQuery.of(context).size.width * 0.45,
//     margin: const EdgeInsets.only(top: 10.0),
//     padding: const EdgeInsets.all(16.0),
//     decoration: BoxDecoration(
//       color: Colors.blue.shade100,
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: <Widget>[
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             AppTextLarge(
//               text: period,
//               size: 16,
//             ),
//             AppText(
//               text: billets,
//             ),
//           ],
//         ),
//         AppTextLarge(
//           text: 'Fc ${sales.toStringAsFixed(2)}',
//           size: 18,
//         ),
//       ],
//     ),
//   );
// }

// }

// class SalesData {
//   SalesData(this.year, this.sales);
//   final String year;
//   final double sales;
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:intl/intl.dart';

import 'package:taxaero/pages/invoice_forme.dart';
import 'package:taxaero/pages/user_page.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/app_text_large.dart';
import 'package:taxaero/widget/constantes.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SharedPreferences prefs;
  final _totalBillTodayController = StreamController<double>.broadcast();
  final _numberOfInvoicesTodayController = StreamController<int>.broadcast();
  late List<SalesData> salesDataList = [];
  double totalBillYesterday = 0.0;
  int numberOfInvoicesYesterday = 0;
  double totalBillLastMonth = 0.0;
  int numberOfInvoicesLastMonth = 0;

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
    fetchData();
    scheduleEndOfDayTask();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _totalBillTodayController.close();
    _numberOfInvoicesTodayController.close();
    super.dispose();
  }

  void initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      totalBillYesterday = prefs.getDouble('totalBillYesterday') ?? 0.0;
      numberOfInvoicesYesterday =
          prefs.getInt('numberOfInvoicesYesterday') ?? 0;
      totalBillLastMonth = prefs.getDouble('totalBillLastMonth') ?? 0.0;
      numberOfInvoicesLastMonth =
          prefs.getInt('numberOfInvoicesLastMonth') ?? 0;
      print('Retrieved totalBillYesterday: $totalBillYesterday');
      print('Retrieved numberOfInvoicesYesterday: $numberOfInvoicesYesterday');
      print('Retrieved totalBillLastMonth: $totalBillLastMonth');
      print('Retrieved numberOfInvoicesLastMonth: $numberOfInvoicesLastMonth');
    });
  }

  void fetchData() async {
    if (!_totalBillTodayController.isClosed &&
        !_numberOfInvoicesTodayController.isClosed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      List<dynamic> allInvoices = [];
      int page = 1;
      bool morePagesAvailable = true;

      while (morePagesAvailable) {
        final url =
            Uri.parse('https://taxe.happook.com/api/invoices?page=$page');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final List<dynamic> invoices = jsonData['hydra:member'];

          if (invoices.isEmpty) {
            morePagesAvailable = false;
          } else {
            allInvoices.addAll(invoices);
            page++;
          }
        } else {
          print('Failed to fetch data. Status code: ${response.statusCode}');
          break;
        }
      }

      final todayInvoices = allInvoices.where((invoice) {
        final invoiceDateStr = invoice['createdAt'];
        if (invoiceDateStr != null) {
          final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
          return invoiceDate.year == today.year &&
              invoiceDate.month == today.month &&
              invoiceDate.day == today.day;
        }
        return false;
      }).toList();

      final numberOfInvoicesToday = todayInvoices.length;
      final totalBillToday = todayInvoices.fold(0.0, (sum, invoice) {
        final bill = invoice['bill'];
        if (bill != null && double.tryParse(bill) != null) {
          return sum + double.parse(bill);
        }
        return sum;
      }).toDouble();

      if (!_totalBillTodayController.isClosed) {
        _totalBillTodayController.add(totalBillToday);
      }
      if (!_numberOfInvoicesTodayController.isClosed) {
        _numberOfInvoicesTodayController.add(numberOfInvoicesToday);
      }

      updateSalesDataList(allInvoices);

      print('Nombre de factures vendues aujourd\'hui : $numberOfInvoicesToday');
      print('Total des montants vendus aujourd\'hui : $totalBillToday');
    }
  }

  void updateSalesDataList(List<dynamic> invoices) {
    salesDataList = [];

    salesDataList
        .add(SalesData('Lun', getTotalSalesForDay(invoices, DateTime.monday)));
    salesDataList
        .add(SalesData('Mar', getTotalSalesForDay(invoices, DateTime.tuesday)));
    salesDataList.add(
        SalesData('Mer', getTotalSalesForDay(invoices, DateTime.wednesday)));
    salesDataList.add(
        SalesData('Jeu', getTotalSalesForDay(invoices, DateTime.thursday)));
    salesDataList
        .add(SalesData('Ven', getTotalSalesForDay(invoices, DateTime.friday)));
    salesDataList.add(
        SalesData('Sam', getTotalSalesForDay(invoices, DateTime.saturday)));
    salesDataList
        .add(SalesData('Dim', getTotalSalesForDay(invoices, DateTime.sunday)));

    setState(() {
      print('Sales data updated');
      salesDataList.forEach((data) {
        print('${data.year}: ${data.sales}');
      });
    });
  }

  double getTotalSalesForDay(List<dynamic> invoices, int dayOfWeek) {
    final salesForDay = invoices.where((invoice) {
      final invoiceDateStr = invoice['createdAt'];
      if (invoiceDateStr != null) {
        final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
        return invoiceDate.weekday == dayOfWeek;
      }
      return false;
    }).toList();

    return salesForDay.fold(0.0, (sum, invoice) {
      final bill = invoice['bill'];
      if (bill != null && double.tryParse(bill) != null) {
        return sum + double.parse(bill);
      }
      return sum;
    });
  }

  void storeYesterdayData(double totalBill, int numberOfInvoices) async {
    prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalBillYesterday', totalBill);
    await prefs.setInt('numberOfInvoicesYesterday', numberOfInvoices);
    print('Storing totalBillYesterday: $totalBill');
    print('Storing numberOfInvoicesYesterday: $numberOfInvoices');
  }

  void scheduleEndOfDayTask() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final durationUntilEndOfDay = endOfDay.difference(now);

    Timer(durationUntilEndOfDay, () async {
      final totalBillToday = await _totalBillTodayController.stream.first;
      final numberOfInvoicesToday =
          await _numberOfInvoicesTodayController.stream.first;
      storeYesterdayData(totalBillToday, numberOfInvoicesToday);
      print(
          'End of day data stored - Sales: $totalBillToday, Invoices: $numberOfInvoicesToday');
    });
  }

  String customNumberFormat(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    AppTextLarge(
                      text: 'Taxe Moto',
                      size: 40,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserPage(),
                          ),
                        );
                      },
                      child: Card(
                        child: Container(
                          height: 50,
                          width: 50,
                          child: IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                backgroundColor: Colors.transparent,
                                useSafeArea: true,
                                context: context,
                                builder: (context) {
                                  return Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white),
                                    child: const UserPage(),
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.person),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                StreamBuilder<double>(
                  stream: _totalBillTodayController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(text: 'TOTAL VENTE AUJOURD\'HUI'),
                            AppTextLarge(
                              text: 'Fc ${snapshot.data!.toStringAsFixed(2)}',
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const Text('chargement ...');
                    }
                  },
                ),
                sizedbox,
                StreamBuilder<int>(
                  stream: _numberOfInvoicesTodayController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(text: 'Nombre de facture'),
                            AppTextLarge(
                              text: snapshot.data.toString(),
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const Text('chargement ...');
                    }
                  },
                ),
                sizedbox,
                Padding(
                  padding: EdgeInsets.only(left: 15.0),
                  child: AppText(text: 'VENTE DEJA ENREGISTRE'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatContainer(context, 'Hier:', totalBillYesterday,
                        '$numberOfInvoicesYesterday Tck'),
                    _buildStatContainer(context, 'Mois Passé:',
                        totalBillLastMonth, '$numberOfInvoicesLastMonth Tck'),
                  ],
                ),
                sizedbox,
                Padding(
                  padding: EdgeInsets.only(left: 15.0,bottom: 10),
                  child: AppText(text: 'VENTE SEMAINE'),
                ),
                SfCartesianChart(
                  primaryXAxis: const CategoryAxis(
                    labelStyle:  TextStyle(fontSize: 10),
                  ),
                  primaryYAxis: NumericAxis(
                      labelStyle: const TextStyle(fontSize: 10),
                      numberFormat: NumberFormat.compact()),
                  series: <ColumnSeries<SalesData, String>>[
                    ColumnSeries<SalesData, String>(
                      dataSource: salesDataList,
                      xValueMapper: (SalesData sales, _) => sales.year,
                      yValueMapper: (SalesData sales, _) => sales.sales,
                      isTrackVisible: true,
                      borderRadius: BorderRadius.circular(10),
                    )
                  ],
                ),
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
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            context: context,
            builder: (context) {
              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white),
                child: const EditTaxFormPage(),
              );
            },
          );
        },
        child: const Icon(Icons.note_add),
      ),
    );
  }

  Widget _buildStatContainer(
      BuildContext context, String period, double sales, String billets) {
    print('$period - Sales: $sales, Billets: $billets');
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.45,
      margin: const EdgeInsets.only(top: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppTextLarge(
                text: period,
                size: 16,
              ),
              AppText(
                text: billets,
              ),
            ],
          ),
          AppTextLarge(
            text: 'Fc ${sales.toStringAsFixed(2)}',
            size: 18,
          ),
        ],
      ),
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales);

  final String year;
  final double sales;
}
