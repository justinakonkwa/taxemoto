// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:taxaero/connectivity.dart';
import 'package:taxaero/database/database_helper.dart';
import 'package:taxaero/pages/invoice_forme.dart';
import 'package:taxaero/pages/localhistory.dart';
import 'package:taxaero/pages/user_page.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/app_text_large.dart';
import 'package:taxaero/widget/constantes.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _ExempleState();
}

class _ExempleState extends State<HomePage> {
  late SharedPreferences prefs;
  final _totalBillTodayController = StreamController<double>.broadcast();
  final _numberOfInvoicesTodayController = StreamController<int>.broadcast();
  List<SalesData> salesDataList = []; // Remove 'late' and initialize as empty
  double totalBillYesterday = 0.0;
  int numberOfInvoicesYesterday = 0;
  double totalBillLastMonth = 0.0;
  int numberOfInvoicesLastMonth = 0;
  final InvoiceSyncService _invoiceSyncService = InvoiceSyncService();
  final LocalDatabase _localDatabase = LocalDatabase();
  // final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
    fetchData();
    scheduleEndOfDayTask();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchData();
    });
    // _connectivityService.connectivityStream.listen((connectivityResult) {
    //   if (connectivityResult.isNotEmpty &&
    //       connectivityResult[0] != ConnectivityResult.none) {
    //     syncInvoices(context);
    //     _localDatabase.deleteAllInvoices();
    //   }
    // });
  }

  @override
  void dispose() {
    _totalBillTodayController.close();
    _numberOfInvoicesTodayController.close();
    super.dispose();
  }

  Future<void> syncInvoices(BuildContext context) async {
    try {
      await _invoiceSyncService.syncPendingInvoices();
      await _localDatabase.deleteAllInvoices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisation réussie !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la synchronisation : $e')),
      );
    }
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

      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayInvoices = allInvoices.where((invoice) {
        final invoiceDateStr = invoice['createdAt'];
        if (invoiceDateStr != null) {
          final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
          return invoiceDate.year == yesterday.year &&
              invoiceDate.month == yesterday.month &&
              invoiceDate.day == yesterday.day;
        }
        return false;
      }).toList();

      final numberOfInvoicesYesterday = yesterdayInvoices.length;
      final totalBillYesterday = yesterdayInvoices.fold(0.0, (sum, invoice) {
        final amount = invoice['amount'];
        if (amount != null && amount is int) {
          return sum + amount;
        }
        return sum;
      }).toDouble();

      await storeYesterdayData(totalBillYesterday, numberOfInvoicesYesterday);

      final lastMonth = DateTime(now.year, now.month - 1);
      final lastMonthInvoices = allInvoices.where((invoice) {
        final invoiceDateStr = invoice['createdAt'];
        if (invoiceDateStr != null) {
          final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
          return invoiceDate.year == lastMonth.year &&
              invoiceDate.month == lastMonth.month;
        }
        return false;
      }).toList();

      final numberOfInvoicesLastMonth = lastMonthInvoices.length;
      final totalBillLastMonth = lastMonthInvoices.fold(0.0, (sum, invoice) {
        final amount = invoice['amount'];
        if (amount != null && amount is int) {
          return sum + amount;
        }
        return sum;
      }).toDouble();

      setState(() {
        this.numberOfInvoicesLastMonth = numberOfInvoicesLastMonth;
        this.totalBillLastMonth = totalBillLastMonth;
      });

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
        final amount = invoice['amount'];
        if (amount != null && amount is int) {
          return sum + amount;
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
    }
  }

  Future<void> storeYesterdayData(
      double totalBill, int numberOfInvoices) async {
    prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalBillYesterday', totalBill);
    await prefs.setInt('numberOfInvoicesYesterday', numberOfInvoices);
  }

  void scheduleEndOfDayTask() {
    final now = DateTime.now();
    final endOfDay =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    final durationUntilEndOfDay = endOfDay.difference(now);

    Timer(durationUntilEndOfDay, () async {
      final totalBillToday = await _totalBillTodayController.stream.first;
      final numberOfInvoicesToday =
          await _numberOfInvoicesTodayController.stream.first;
      storeYesterdayData(totalBillToday, numberOfInvoicesToday);
    });
  }

  void updateSalesDataList(List<dynamic> invoices) {
    salesDataList = [
      SalesData('Lun', getTotalSalesForDay(invoices, DateTime.monday)),
      SalesData('Mar', getTotalSalesForDay(invoices, DateTime.tuesday)),
      SalesData('Mer', getTotalSalesForDay(invoices, DateTime.wednesday)),
      SalesData('Jeu', getTotalSalesForDay(invoices, DateTime.thursday)),
      SalesData('Ven', getTotalSalesForDay(invoices, DateTime.friday)),
      SalesData('Sam', getTotalSalesForDay(invoices, DateTime.saturday)),
      SalesData('Dim', getTotalSalesForDay(invoices, DateTime.sunday)),
    ];

    setState(() {}); // Call setState to rebuild the widget with new data
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
      final bill = invoice['amount'];
      if (bill != null && bill is int) {
        return sum + bill;
      }
      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          CustomAppBar(),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Padding(
                  padding:
                      const EdgeInsets.only(top: 10.0, left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StreamBuilder<double>(
                            stream: _totalBillTodayController.stream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(text: 'TOTAL VENTE AUJOURD\'HUI'),
                                    AppTextLarge(
                                      text:
                                          'Fc ${snapshot.data!.toStringAsFixed(2)}',
                                      size: 20,
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(text: 'VENTE AUJOURD\'HUI'),
                                    const Text('chargement ...'),
                                  ],
                                );
                              }
                            },
                          ),
                          StreamBuilder<int>(
                            stream: _numberOfInvoicesTodayController.stream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppText(text: 'Tickets'),
                                    AppTextLarge(
                                      text: snapshot.data.toString(),
                                      size: 20,
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppText(text: 'Tickets'),
                                    const Text('chargement ...'),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      sizedbox,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatContainer(
                              context,
                              'Hier:',
                              totalBillYesterday,
                              '$numberOfInvoicesYesterday Tck'),
                          _buildStatContainer(
                              context,
                              'Mois denier:',
                              totalBillLastMonth,
                              '$numberOfInvoicesLastMonth T'),
                        ],
                      ),
                      sizedbox,
                      sizedbox,
                      AppText(text: 'STATISTIQUE SEMAINE'),
                      sizedbox,
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(20.0),),
                        child: SfCartesianChart(
                          primaryXAxis: const CategoryAxis(
                            majorGridLines: MajorGridLines(width: 0),
                            labelStyle: TextStyle(fontSize: 10),
                          ),
                          primaryYAxis: NumericAxis(
                            labelStyle: const TextStyle(fontSize: 10),
                            numberFormat: NumberFormat.compact(),
                            majorGridLines: const MajorGridLines(width: 0),
                          ),
                          series: <ColumnSeries<SalesData, String>>[
                            ColumnSeries<SalesData, String>(
                              color: Theme.of(context).colorScheme.primary,
                              borderColor:
                                  Theme.of(context).colorScheme.secondary,
                              trackColor:
                                  Theme.of(context).colorScheme.secondary,
                              trackBorderColor:
                                  Theme.of(context).colorScheme.primary,
                              animationDuration: 1000,
                              dataSource: salesDataList,
                              xValueMapper: (SalesData sales, _) => sales.year,
                              yValueMapper: (SalesData sales, _) => sales.sales,
                              isTrackVisible: true,
                              borderRadius: BorderRadius.circular(10),
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                opacity: 12,
                                textStyle: TextStyle(
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
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
                child: const InvoicePage(),
              );
            },
          );
        },
        child: Icon(
          Icons.note_add,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildStatContainer(
      BuildContext context, String period, double sales, String billets) {
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.45,
      margin: const EdgeInsets.only(top: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
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
            // color: Colors.white,
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

class CustomAppBar extends StatefulWidget {
  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final bool _pinned = true;

  final InvoiceSyncService _invoiceSyncService = InvoiceSyncService();
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
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: _pinned,
      expandedHeight: 130.0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 10),
        centerTitle: false,
        title: Container(
          margin: const EdgeInsets.only(bottom: 5.0),
          alignment: Alignment.centerLeft,
          height: MediaQuery.of(context).size.height * 0.06,
          width: 100,
          child: Image.asset('assets/intro3.png'),
        ),
        background: Container(
          decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(20.0),
              color: Theme.of(context).colorScheme.primary),
        ),
      ),
      title: AppTextLarge(
        text: 'TaxeMoto',
        size: 40,
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30.0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(5),
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.sync),
                      onPressed: () {
                        syncInvoices(context);
                      },
                    ),
                  ),
                  if (_invoices != 0)
                    Positioned(
                      left: 30,
                      bottom: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: AppText(
                          text: '${_invoices.length}',
                          color: Theme.of(context).colorScheme.secondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Container(
                margin: const EdgeInsets.all(5.0),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: IconButton(
                  icon: const Icon(Icons.turned_in_not),
                  onPressed: () {
                    showModalBottomSheet(
                      useSafeArea: true,
                      context: context,
                      builder: (context) {
                        return const InvoiceListPage();
                      },
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(5.0),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.person),
                  onPressed: () {
                    showModalBottomSheet(
                      useSafeArea: true,
                      context: context,
                      builder: (context) {
                        return const UserPage();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> syncInvoices(BuildContext context) async {
    try {
      await _invoiceSyncService.syncPendingInvoices();
      await _localDatabase.deleteAllInvoices();
      _fetchInvoices(); // Suppression des données après la synchronisation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: AppText(
            text: 'Synchronisation réussie !',
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: AppText(
            text: 'Erreur lors de la synchronisation : $e',
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    }
  }
}



// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:syncfusion_flutter_charts/charts.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:async';

// // import 'package:taxaero/pages/invoice_forme.dart';
// // import 'package:taxaero/pages/user_page.dart';
// // import 'package:taxaero/widget/app_text.dart';
// // import 'package:taxaero/widget/app_text_large.dart';
// // import 'package:taxaero/widget/constantes.dart';

// // class HomePage extends StatefulWidget {
// //   const HomePage({Key? key}) : super(key: key);

// //   @override
// //   State<HomePage> createState() => _HomePageState();
// // }

// // class _HomePageState extends State<HomePage> {
// //   late SharedPreferences prefs;
// //   final _totalBillTodayController = StreamController<double>.broadcast();
// //   final _numberOfInvoicesTodayController = StreamController<int>.broadcast();
// //   late List<SalesData> salesDataList = [];
// //   double totalBillYesterday = 0.0;
// //   int numberOfInvoicesYesterday = 0;
// //   double totalBillLastMonth = 0.0;
// //   int numberOfInvoicesLastMonth = 0;

// // @override
// // void initState() {
// //   super.initState();
// //   initSharedPreferences();
// //   fetchData();
// //   scheduleEndOfDayTask();
// //   Timer.periodic(const Duration(seconds: 10), (timer) {
// //     fetchData();
// //   });
// // }

// //   @override
// //   void dispose() {
// //     _totalBillTodayController.close();
// //     _numberOfInvoicesTodayController.close();
// //     super.dispose();
// //   }

// // void initSharedPreferences() async {
// //   prefs = await SharedPreferences.getInstance();
// //   setState(() {
// //     totalBillYesterday = prefs.getDouble('totalBillYesterday') ?? 0.0;
// //     numberOfInvoicesYesterday = prefs.getInt('numberOfInvoicesYesterday') ?? 0;
// //     totalBillLastMonth = prefs.getDouble('totalBillLastMonth') ?? 0.0;
// //     numberOfInvoicesLastMonth = prefs.getInt('numberOfInvoicesLastMonth') ?? 0;
// //     print('Retrieved totalBillYesterday: $totalBillYesterday');
// //     print('Retrieved numberOfInvoicesYesterday: $numberOfInvoicesYesterday');
// //     print('Retrieved totalBillLastMonth: $totalBillLastMonth');
// //     print('Retrieved numberOfInvoicesLastMonth: $numberOfInvoicesLastMonth');
// //   });
// // }

// // void fetchData() async {
// //   if (!_totalBillTodayController.isClosed && !_numberOfInvoicesTodayController.isClosed) {
// //     final now = DateTime.now();
// //     final today = DateTime(now.year, now.month, now.day);

// //     final url = Uri.parse('https://taxe.happook.com/api/invoices');
// //     final response = await http.get(url);

// //     if (response.statusCode == 200) {
// //       final jsonData = json.decode(response.body);
// //       final List<dynamic> invoices = jsonData['hydra:member'];

// //       final todayInvoices = invoices.where((invoice) {
// //         final invoiceDateStr = invoice['createdAt'];
// //         if (invoiceDateStr != null) {
// //           final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
// //           return invoiceDate.year == today.year && invoiceDate.month == today.month && invoiceDate.day == today.day;
// //         }
// //         return false;
// //       }).toList();

// //       final numberOfInvoicesToday = todayInvoices.length;
// //       final totalBillToday = todayInvoices.fold(0.0, (sum, invoice) {
// //         final bill = invoice['bill'];
// //         if (bill != null && double.tryParse(bill) != null) {
// //           return sum + double.parse(bill);
// //         }
// //         return sum;
// //       }).toDouble();

// //       if (!_totalBillTodayController.isClosed) {
// //         _totalBillTodayController.add(totalBillToday);
// //       }
// //       if (!_numberOfInvoicesTodayController.isClosed) {
// //         _numberOfInvoicesTodayController.add(numberOfInvoicesToday);
// //       }

// //       updateSalesDataList(invoices);

// //       // Log today's data
// //       print('Nombre de factures vendues aujourd\'hui : $numberOfInvoicesToday');
// //       print('Total des montants vendus aujourd\'hui : $totalBillToday');
// //     } else {
// //       print('Failed to fetch data. Status code: ${response.statusCode}');
// //     }
// //   }
// // }

// // void updateSalesDataList(List<dynamic> invoices) {
// //   salesDataList = [];

// //   salesDataList.add(SalesData('Lun', getTotalSalesForDay(invoices, DateTime.monday)));
// //   salesDataList.add(SalesData('Mar', getTotalSalesForDay(invoices, DateTime.tuesday)));
// //   salesDataList.add(SalesData('Mer', getTotalSalesForDay(invoices, DateTime.wednesday)));
// //   salesDataList.add(SalesData('Jeu', getTotalSalesForDay(invoices, DateTime.thursday)));
// //   salesDataList.add(SalesData('Ven', getTotalSalesForDay(invoices, DateTime.friday)));
// //   salesDataList.add(SalesData('Sam', getTotalSalesForDay(invoices, DateTime.saturday)));
// //   salesDataList.add(SalesData('Dim', getTotalSalesForDay(invoices, DateTime.sunday)));

// //   setState(() {
// //     print('Sales data updated');
// //     salesDataList.forEach((data) {
// //       print('${data.year}: ${data.sales}');
// //     });
// //   });
// // }

// //   double getTotalSalesForDay(List<dynamic> invoices, int dayOfWeek) {
// //     final salesForDay = invoices.where((invoice) {
// //       final invoiceDateStr = invoice['createdAt'];
// //       if (invoiceDateStr != null) {
// //         final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
// //         return invoiceDate.weekday == dayOfWeek;
// //       }
// //       return false;
// //     }).toList();

// //     return salesForDay.fold(0.0, (sum, invoice) {
// //       final bill = invoice['bill'];
// //       if (bill != null && double.tryParse(bill) != null) {
// //         return sum + double.parse(bill);
// //       }
// //       return sum;
// //     });
// //   }

// // void storeYesterdayData(double totalBill, int numberOfInvoices) async {
// //   prefs = await SharedPreferences.getInstance();
// //   await prefs.setDouble('totalBillYesterday', totalBill);
// //   await prefs.setInt('numberOfInvoicesYesterday', numberOfInvoices);
// //   print('Storing totalBillYesterday: $totalBill');
// //   print('Storing numberOfInvoicesYesterday: $numberOfInvoices');
// // }

// // void scheduleEndOfDayTask() {
// //   final now = DateTime.now();
// //   final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

// //   Timer(Duration(milliseconds: endOfDay.millisecondsSinceEpoch - now.millisecondsSinceEpoch), () async {
// //     final totalBillToday = await _totalBillTodayController.stream.first;
// //     final numberOfInvoicesToday = await _numberOfInvoicesTodayController.stream.first;
// //     storeYesterdayData(totalBillToday, numberOfInvoicesToday);
// //     print('End of day task executed');
// //   });
// // }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SafeArea(
// //         child: SingleChildScrollView(
// //           child: Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: <Widget>[
// //                 Row(
// //                   children: [
// //                     AppTextLarge(
// //                       text: 'Taxe Moto',
// //                       size: 40,
// //                     ),
// //                     const Spacer(),
// //                     GestureDetector(
// //                       onTap: () {
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (context) => const UserPage(),
// //                           ),
// //                         );
// //                       },
// //                       child: Card(
// //                         child: Container(
// //                           height: 50,
// //                           width: 50,
// //                           child: IconButton(
// //                             onPressed: () {
// //                               showModalBottomSheet(
// //                                 backgroundColor: Colors.transparent,
// //                                 useSafeArea: true,
// //                                 context: context,
// //                                 builder: (context) {
// //                                   return Container(
// //                                     decoration: BoxDecoration(
// //                                         borderRadius: BorderRadius.circular(20),
// //                                         color: Colors.white),
// //                                     child: const UserPage(),
// //                                   );
// //                                 },
// //                               );
// //                             },
// //                             icon: Icon(Icons.person),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 20),
// //                 StreamBuilder<double>(
// //                   stream: _totalBillTodayController.stream,
// //                   builder: (context, snapshot) {
// //                     if (snapshot.hasData) {
// //                       return Padding(
// //                         padding: const EdgeInsets.only(left: 15.0),
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             AppText(text: 'TOTAL VENTE AUJOURD\'HUI'),
// //                             AppTextLarge(
// //                               text: 'Fc ${snapshot.data!.toStringAsFixed(2)}',
// //                               size: 20,
// //                             ),
// //                           ],
// //                         ),
// //                       );
// //                     } else {
// //                       return const Text('chargement ...');
// //                     }
// //                   },
// //                 ),
// //                 sizedbox,
// //                 StreamBuilder<int>(
// //                   stream: _numberOfInvoicesTodayController.stream,
// //                   builder: (context, snapshot) {
// //                     if (snapshot.hasData) {
// //                       return Padding(
// //                         padding: const EdgeInsets.only(left: 15.0),
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             AppText(
// //                               text: 'TICKETS VENDU',
// //                               size: 18,
// //                             ),
// //                             AppTextLarge(
// //                               text: '${snapshot.data}',
// //                               size: 18,
// //                             ),
// //                           ],
// //                         ),
// //                       );
// //                     } else {
// //                       return const Text('chargement ...');
// //                     }
// //                   },
// //                 ),
// //                 sizedbox,
// //                 Container(
// //                   padding: const EdgeInsets.all(10),
// //                   height: 300.0,
// //                   decoration: BoxDecoration(
// //                       borderRadius: BorderRadius.circular(20),
// //                       color: Colors.blue.shade100),
// //                   child: SfCartesianChart(
// //                     primaryXAxis: const CategoryAxis(),
// //                     series: <ColumnSeries<SalesData, String>>[
// //                       ColumnSeries<SalesData, String>(
// //                         dataSource: salesDataList,
// //                         xValueMapper: (SalesData sales, _) => sales.year,
// //                         yValueMapper: (SalesData sales, _) => sales.sales,
// //                         isTrackVisible: true,
// //                         borderRadius: BorderRadius.circular(10),
// //                       )
// //                     ],
// //                   ),
// //                 ),
// //                 sizedbox,
// //                 Container(
// //                   margin: const EdgeInsets.only(left: 15.0),
// //                   child: AppText(text: 'STATISTIQUE'),
// //                 ),

// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     _buildStatContainer(context, 'Hier:', totalBillYesterday,
// //                         '$numberOfInvoicesYesterday Tck'),
// //                     _buildStatContainer(context, 'Mois Passé:',
// //                         totalBillLastMonth, '$numberOfInvoicesLastMonth Tck'),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         shape: RoundedRectangleBorder(
// //           borderRadius:
// //               BorderRadius.circular(30), // Set your desired border radius here
// //         ),
// //         onPressed: () {
// //           showModalBottomSheet(
// //             backgroundColor: Colors.transparent,
// //             useSafeArea: true,
// //             context: context,
// //             builder: (context) {
// //               return Container(
// //                 decoration: BoxDecoration(
// //                     borderRadius: BorderRadius.circular(20),
// //                     color: Colors.white),
// //                 child: const EditTaxFormPage(),
// //               );
// //             },
// //           );
// //         },
// //         child: const Icon(Icons.note_add),
// //       ),
// //     );
// //   }
// // Widget _buildStatContainer(
// //     BuildContext context, String period, double sales, String billets) {
// //   print('$period - Sales: $sales, Billets: $billets');

// //   return Container(
// //     height: 100,
// //     width: MediaQuery.of(context).size.width * 0.45,
// //     margin: const EdgeInsets.only(top: 10.0),
// //     padding: const EdgeInsets.all(16.0),
// //     decoration: BoxDecoration(
// //       color: Colors.blue.shade100,
// //       borderRadius: BorderRadius.circular(20),
// //     ),
// //     child: Column(
// //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //       children: <Widget>[
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             AppTextLarge(
// //               text: period,
// //               size: 16,
// //             ),
// //             AppText(
// //               text: billets,
// //             ),
// //           ],
// //         ),
// //         AppTextLarge(
// //           text: 'Fc ${sales.toStringAsFixed(2)}',
// //           size: 18,
// //         ),
// //       ],
// //     ),
// //   );
// // }

// // }

// // class SalesData {
// //   SalesData(this.year, this.sales);
// //   final String year;
// //   final double sales;
// // }
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:syncfusion_flutter_charts/charts.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:async';
// // import 'package:intl/intl.dart';

// // import 'package:taxaero/pages/invoice_forme.dart';
// // import 'package:taxaero/pages/user_page.dart';
// // import 'package:taxaero/widget/app_text.dart';
// // import 'package:taxaero/widget/app_text_large.dart';
// // import 'package:taxaero/widget/constantes.dart';

// // class HomePage extends StatefulWidget {
// //   const HomePage({Key? key}) : super(key: key);

// //   @override
// //   State<HomePage> createState() => _HomePageState();
// // }

// // class _HomePageState extends State<HomePage> {
// //   late SharedPreferences prefs;
// //   final _totalBillTodayController = StreamController<double>.broadcast();
// //   final _numberOfInvoicesTodayController = StreamController<int>.broadcast();
// //   late List<SalesData> salesDataList = [];
// //   double totalBillYesterday = 0.0;
// //   int numberOfInvoicesYesterday = 0;
// //   double totalBillLastMonth = 0.0;
// //   int numberOfInvoicesLastMonth = 0;

// //   @override
// //   void initState() {
// //     super.initState();
// //     initSharedPreferences();
// //     fetchData();
// //     scheduleEndOfDayTask();
// //     Timer.periodic(const Duration(seconds: 10), (timer) {
// //       fetchData();
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     _totalBillTodayController.close();
// //     _numberOfInvoicesTodayController.close();
// //     super.dispose();
// //   }

// //   void initSharedPreferences() async {
// //     prefs = await SharedPreferences.getInstance();
// //     setState(() {
// //       totalBillYesterday = prefs.getDouble('totalBillYesterday') ?? 0.0;
// //       numberOfInvoicesYesterday =
// //           prefs.getInt('numberOfInvoicesYesterday') ?? 0;
// //       totalBillLastMonth = prefs.getDouble('totalBillLastMonth') ?? 0.0;
// //       numberOfInvoicesLastMonth =
// //           prefs.getInt('numberOfInvoicesLastMonth') ?? 0;
// //       print('Retrieved totalBillYesterday: $totalBillYesterday');
// //       print('Retrieved numberOfInvoicesYesterday: $numberOfInvoicesYesterday');
// //       print('Retrieved totalBillLastMonth: $totalBillLastMonth');
// //       print('Retrieved numberOfInvoicesLastMonth: $numberOfInvoicesLastMonth');
// //     });
// //   }

// //   void fetchData() async {
// //     if (!_totalBillTodayController.isClosed &&
// //         !_numberOfInvoicesTodayController.isClosed) {
// //       final now = DateTime.now();
// //       final today = DateTime(now.year, now.month, now.day);

// //       List<dynamic> allInvoices = [];
// //       int page = 1;
// //       bool morePagesAvailable = true;

// //       while (morePagesAvailable) {
// //         final url =
// //             Uri.parse('https://taxe.happook.com/api/invoices?page=$page');
// //         final response = await http.get(url);

// //         if (response.statusCode == 200) {
// //           final jsonData = json.decode(response.body);
// //           final List<dynamic> invoices = jsonData['hydra:member'];

// //           if (invoices.isEmpty) {
// //             morePagesAvailable = false;
// //           } else {
// //             allInvoices.addAll(invoices);
// //             page++;
// //           }
// //         } else {
// //           print('Failed to fetch data. Status code: ${response.statusCode}');
// //           break;
// //         }
// //       }

// //       final yesterday = today.subtract(Duration(days: 1));
// //       final yesterdayInvoices = allInvoices.where((invoice) {
// //         final invoiceDateStr = invoice['createdAt'];
// //         if (invoiceDateStr != null) {
// //           final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
// //           return invoiceDate.year == yesterday.year &&
// //               invoiceDate.month == yesterday.month &&
// //               invoiceDate.day == yesterday.day;
// //         }
// //         return false;
// //       }).toList();

// //       final numberOfInvoicesYesterday = yesterdayInvoices.length;
// //       final totalBillYesterday = yesterdayInvoices.fold(0.0, (sum, invoice) {
// //         final amount = invoice['amount'];
// //         if (amount != null && amount is int) {
// //           return sum + amount;
// //         }
// //         return sum;
// //       }).toDouble();

// //       await storeYesterdayData(totalBillYesterday, numberOfInvoicesYesterday);

// //       final lastMonth = DateTime(now.year, now.month - 1);
// //       final lastMonthInvoices = allInvoices.where((invoice) {
// //         final invoiceDateStr = invoice['createdAt'];
// //         if (invoiceDateStr != null) {
// //           final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
// //           return invoiceDate.year == lastMonth.year &&
// //               invoiceDate.month == lastMonth.month;
// //         }
// //         return false;
// //       }).toList();

// //       final numberOfInvoicesLastMonth = lastMonthInvoices.length;
// //       final totalBillLastMonth = lastMonthInvoices.fold(0.0, (sum, invoice) {
// //         final amount = invoice['amount'];
// //         if (amount != null && amount is int) {
// //           return sum + amount;
// //         }
// //         return sum;
// //       }).toDouble();

// //       setState(() {
// //         this.numberOfInvoicesLastMonth = numberOfInvoicesLastMonth;
// //         this.totalBillLastMonth = totalBillLastMonth;
// //       });

// //       final todayInvoices = allInvoices.where((invoice) {
// //         final invoiceDateStr = invoice['createdAt'];
// //         if (invoiceDateStr != null) {
// //           final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
// //           return invoiceDate.year == today.year &&
// //               invoiceDate.month == today.month &&
// //               invoiceDate.day == today.day;
// //         }
// //         return false;
// //       }).toList();

// //       final numberOfInvoicesToday = todayInvoices.length;
// //       final totalBillToday = todayInvoices.fold(0.0, (sum, invoice) {
// //         final amount = invoice['amount'];
// //         if (amount != null && amount is int) {
// //           return sum + amount;
// //         }
// //         return sum;
// //       }).toDouble();

// //       if (!_totalBillTodayController.isClosed) {
// //         _totalBillTodayController.add(totalBillToday);
// //       }
// //       if (!_numberOfInvoicesTodayController.isClosed) {
// //         _numberOfInvoicesTodayController.add(numberOfInvoicesToday);
// //       }

// //       updateSalesDataList(allInvoices);

// //       print('Nombre de factures vendues aujourd\'hui : $numberOfInvoicesToday');
// //       print('Total des montants vendus aujourd\'hui : $totalBillToday');
// //     }
// //   }

// //   Future<void> storeYesterdayData(
// //       double totalBill, int numberOfInvoices) async {
// //     prefs = await SharedPreferences.getInstance();
// //     await prefs.setDouble('totalBillYesterday', totalBill);
// //     await prefs.setInt('numberOfInvoicesYesterday', numberOfInvoices);
// //     print('Storing totalBillYesterday: $totalBill');
// //     print('Storing numberOfInvoicesYesterday: $numberOfInvoices');
// //   }

// //   void scheduleEndOfDayTask() {
// //     final now = DateTime.now();
// //     final endOfDay = DateTime(now.year,now.month,now.day);


// //     final durationUntilEndOfDay = endOfDay.difference(now);

// //     Timer(durationUntilEndOfDay, () async {
// //       final totalBillToday = await _totalBillTodayController.stream.first;
// //       final numberOfInvoicesToday =
// //           await _numberOfInvoicesTodayController.stream.first;
// //       storeYesterdayData(totalBillToday, numberOfInvoicesToday);
// //       print(
// //           'End of day data stored - Sales: $totalBillToday, Invoices: $numberOfInvoicesToday');
// //     });
// //   }

// //   void updateSalesDataList(List<dynamic> invoices) {
// //     salesDataList = [];

// //     salesDataList
// //         .add(SalesData('Lun', getTotalSalesForDay(invoices, DateTime.monday)));
// //     salesDataList
// //         .add(SalesData('Mar', getTotalSalesForDay(invoices, DateTime.tuesday)));
// //     salesDataList.add(
// //         SalesData('Mer', getTotalSalesForDay(invoices, DateTime.wednesday)));
// //     salesDataList.add(
// //         SalesData('Jeu', getTotalSalesForDay(invoices, DateTime.thursday)));
// //     salesDataList
// //         .add(SalesData('Ven', getTotalSalesForDay(invoices, DateTime.friday)));
// //     salesDataList.add(
// //         SalesData('Sam', getTotalSalesForDay(invoices, DateTime.saturday)));
// //     salesDataList
// //         .add(SalesData('Dim', getTotalSalesForDay(invoices, DateTime.sunday)));

// //     setState(() {
// //       print('Sales data updated');
// //       salesDataList.forEach((data) {
// //         print('${data.year}: ${data.sales}');
// //       });
// //     });
// //   }

// //   double getTotalSalesForDay(List<dynamic> invoices, int dayOfWeek) {
// //     final salesForDay = invoices.where((invoice) {
// //       final invoiceDateStr = invoice['createdAt'];
// //       if (invoiceDateStr != null) {
// //         final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
// //         return invoiceDate.weekday == dayOfWeek;
// //       }
// //       return false;
// //     }).toList();

// //     return salesForDay.fold(0.0, (sum, invoice) {
// //       final bill = invoice['amount'];
// //       if (bill != null && double.tryParse(bill) != null) {
// //         return sum + double.parse(bill);
// //       }
// //       return sum;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SafeArea(
// //         child: SingleChildScrollView(
// //           child: Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: <Widget>[
// //                 Row(
// //                   children: [
// //                     AppTextLarge(
// //                       text: 'Taxe Moto',
// //                       size: 40,
// //                     ),
// //                     const Spacer(),
// //                     GestureDetector(
// //                       onTap: () {
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (context) => const UserPage(),
// //                           ),
// //                         );
// //                       },
// //                       child: Card(
// //                         child: Container(
// //                           height: 50,
// //                           width: 50,
// //                           child: IconButton(
// //                             onPressed: () {
// //                               showModalBottomSheet(
// //                                 backgroundColor: Colors.transparent,
// //                                 useSafeArea: true,
// //                                 context: context,
// //                                 builder: (context) {
// //                                   return Container(
// //                                     decoration: BoxDecoration(
// //                                         borderRadius: BorderRadius.circular(20),
// //                                         color: Colors.white),
// //                                     child: const UserPage(),
// //                                   );
// //                                 },
// //                               );
// //                             },
// //                             icon: Icon(Icons.person),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 20),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     StreamBuilder<double>(
// //                       stream: _totalBillTodayController.stream,
// //                       builder: (context, snapshot) {
// //                         if (snapshot.hasData) {
// //                           return Padding(
// //                             padding: const EdgeInsets.only(left: 15.0),
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 AppText(text: 'TOTAL VENTE AUJOURD\'HUI'),
// //                                 AppTextLarge(
// //                                   text:
// //                                       'Fc ${snapshot.data!.toStringAsFixed(2)}',
// //                                   size: 20,
// //                                 ),
// //                               ],
// //                             ),
// //                           );
// //                         } else {
// //                           return const Text('chargement ...');
// //                         }
// //                       },
// //                     ),
// //                     StreamBuilder<int>(
// //                       stream: _numberOfInvoicesTodayController.stream,
// //                       builder: (context, snapshot) {
// //                         if (snapshot.hasData) {
// //                           return Padding(
// //                             padding: const EdgeInsets.only(left: 15.0,right: 10),
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 AppText(text: 'Tickets'),
// //                                 AppTextLarge(
// //                                   text: snapshot.data.toString(),
// //                                   size: 20,
// //                                 ),
// //                               ],
// //                             ),
// //                           );
// //                         } else {
// //                           return const Text('chargement ...');
// //                         }
// //                       },
// //                     ),
// //                   ],
// //                 ),
// //                 sizedbox,
// //                 Padding(
// //                   padding: EdgeInsets.only(left: 15.0),
// //                   child: AppText(text: 'VENTE DEJA ENREGISTRE'),
// //                 ),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
// //                   children: [
// //                     _buildStatContainer(context, 'Hier:', totalBillYesterday,
// //                         '$numberOfInvoicesYesterday Tck'),
// //                     _buildStatContainer(context, 'Mois denier:',
// //                         totalBillLastMonth, '$numberOfInvoicesLastMonth Tck'),
// //                   ],
// //                 ),
// //                 sizedbox,
// //                 Padding(
// //                   padding: EdgeInsets.only(left: 15.0, bottom: 10),
// //                   child: AppText(text: 'VENTE SEMAINE'),
// //                 ),
// //                 SfCartesianChart(
// //                   primaryXAxis: const CategoryAxis(
// //                     labelStyle: TextStyle(fontSize: 10),
// //                   ),
// //                   primaryYAxis: NumericAxis(
// //                     labelStyle: const TextStyle(fontSize: 10),
// //                     numberFormat: NumberFormat.compact(),
// //                   ),
// //                   series: <ColumnSeries<SalesData, String>>[
// //                     ColumnSeries<SalesData, String>(
// //                       dataSource: salesDataList,
// //                       xValueMapper: (SalesData sales, _) => sales.year,
// //                       yValueMapper: (SalesData sales, _) => sales.sales,
// //                       isTrackVisible: true,
// //                       borderRadius: BorderRadius.circular(10),
// //                     )
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         backgroundColor: Colors.blue.shade300,
// //         shape: RoundedRectangleBorder(
// //           borderRadius:
// //               BorderRadius.circular(30), // Set your desired border radius here
// //         ),
// //         onPressed: () {
// //           showModalBottomSheet(
// //             backgroundColor: Colors.transparent,
// //             useSafeArea: true,
// //             context: context,
// //             builder: (context) {
// //               return Container(
// //                 decoration: BoxDecoration(
// //                     borderRadius: BorderRadius.circular(20),
// //                     color: Colors.white),
// //                 child: const EditTaxFormPage(),
// //               );
// //             },
// //           );
// //         },
// //         child: const Icon(Icons.note_add),
// //       ),
// //     );
// //   }

// //   Widget _buildStatContainer(
// //       BuildContext context, String period, double sales, String billets) {
// //     print('$period - Sales: $sales, Billets: $billets');
// //     return Container(
// //       height: 100,
// //       width: MediaQuery.of(context).size.width * 0.45,
// //       margin: const EdgeInsets.only(top: 10.0),
// //       padding: const EdgeInsets.all(16.0),
// //       decoration: BoxDecoration(
// //         color: Colors.blue.shade300,
// //         borderRadius: BorderRadius.circular(20),
// //       ),
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: <Widget>[
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               AppTextLarge(
// //                 text: period,
// //                 size: 16,
// //               ),
// //               AppText(
// //                 text: billets,
// //               ),
// //             ],
// //           ),
// //           AppTextLarge(
// //             text: 'Fc ${sales.toStringAsFixed(2)}',
// //             size: 18,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class SalesData {
// //   SalesData(this.year, this.sales);

// //   final String year;
// //   final double sales;
// // }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:async';
// import 'package:intl/intl.dart';
// import 'package:taxaero/connectivity.dart';
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
//   List<SalesData> salesDataList = []; // Remove 'late' and initialize as empty
//   double totalBillYesterday = 0.0;
//   int numberOfInvoicesYesterday = 0;
//   double totalBillLastMonth = 0.0;
//   int numberOfInvoicesLastMonth = 0;
//     final InvoiceSyncService _invoiceSyncService = InvoiceSyncService(); // Instanciation du service


//   @override
//   void initState() {
//     super.initState();
//     initSharedPreferences();
//     fetchData();
//     scheduleEndOfDayTask();
//     Timer.periodic(const Duration(seconds: 5), (timer) {
//       fetchData();
//     });
//   }

//   @override
//   void dispose() {
//     _totalBillTodayController.close();
//     _numberOfInvoicesTodayController.close();
//     super.dispose();
//   }

//   void initSharedPreferences() async {
//     prefs = await SharedPreferences.getInstance();
//     setState(() {
//       totalBillYesterday = prefs.getDouble('totalBillYesterday') ?? 0.0;
//       numberOfInvoicesYesterday = prefs.getInt('numberOfInvoicesYesterday') ?? 0;
//       totalBillLastMonth = prefs.getDouble('totalBillLastMonth') ?? 0.0;
//       numberOfInvoicesLastMonth = prefs.getInt('numberOfInvoicesLastMonth') ?? 0;
//     });
//   }

//   void fetchData() async {
//     if (!_totalBillTodayController.isClosed && !_numberOfInvoicesTodayController.isClosed) {
//       final now = DateTime.now();
//       final today = DateTime(now.year, now.month, now.day);

//       List<dynamic> allInvoices = [];
//       int page = 1;
//       bool morePagesAvailable = true;

//       while (morePagesAvailable) {
//         final url = Uri.parse('https://taxe.happook.com/api/invoices?page=$page');
//         final response = await http.get(url);

//         if (response.statusCode == 200) {
//           final jsonData = json.decode(response.body);
//           final List<dynamic> invoices = jsonData['hydra:member'];

//           if (invoices.isEmpty) {
//             morePagesAvailable = false;
//           } else {
//             allInvoices.addAll(invoices);
//             page++;
//           }
//         } else {
//           print('Failed to fetch data. Status code: ${response.statusCode}');
//           break;
//         }
//       }

//       final yesterday = today.subtract(Duration(days: 1));
//       final yesterdayInvoices = allInvoices.where((invoice) {
//         final invoiceDateStr = invoice['createdAt'];
//         if (invoiceDateStr != null) {
//           final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
//           return invoiceDate.year == yesterday.year &&
//               invoiceDate.month == yesterday.month &&
//               invoiceDate.day == yesterday.day;
//         }
//         return false;
//       }).toList();

//       final numberOfInvoicesYesterday = yesterdayInvoices.length;
//       final totalBillYesterday = yesterdayInvoices.fold(0.0, (sum, invoice) {
//         final amount = invoice['amount'];
//         if (amount != null && amount is int) {
//           return sum + amount;
//         }
//         return sum;
//       }).toDouble();

//       await storeYesterdayData(totalBillYesterday, numberOfInvoicesYesterday);

//       final lastMonth = DateTime(now.year, now.month - 1);
//       final lastMonthInvoices = allInvoices.where((invoice) {
//         final invoiceDateStr = invoice['createdAt'];
//         if (invoiceDateStr != null) {
//           final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
//           return invoiceDate.year == lastMonth.year && invoiceDate.month == lastMonth.month;
//         }
//         return false;
//       }).toList();

//       final numberOfInvoicesLastMonth = lastMonthInvoices.length;
//       final totalBillLastMonth = lastMonthInvoices.fold(0.0, (sum, invoice) {
//         final amount = invoice['amount'];
//         if (amount != null && amount is int) {
//           return sum + amount;
//         }
//         return sum;
//       }).toDouble();

//       setState(() {
//         this.numberOfInvoicesLastMonth = numberOfInvoicesLastMonth;
//         this.totalBillLastMonth = totalBillLastMonth;
//       });

//       final todayInvoices = allInvoices.where((invoice) {
//         final invoiceDateStr = invoice['createdAt'];
//         if (invoiceDateStr != null) {
//           final invoiceDate = DateTime.parse(invoiceDateStr).toLocal();
//           return invoiceDate.year == today.year &&
//               invoiceDate.month == today.month &&
//               invoiceDate.day == today.day;
//         }
//         return false;
//       }).toList();

//       final numberOfInvoicesToday = todayInvoices.length;
//       final totalBillToday = todayInvoices.fold(0.0, (sum, invoice) {
//         final amount = invoice['amount'];
//         if (amount != null && amount is int) {
//           return sum + amount;
//         }
//         return sum;
//       }).toDouble();

//       if (!_totalBillTodayController.isClosed) {
//         _totalBillTodayController.add(totalBillToday);
//       }
//       if (!_numberOfInvoicesTodayController.isClosed) {
//         _numberOfInvoicesTodayController.add(numberOfInvoicesToday);
//       }

//       updateSalesDataList(allInvoices);
//     }
//   }

//   Future<void> storeYesterdayData(double totalBill, int numberOfInvoices) async {
//     prefs = await SharedPreferences.getInstance();
//     await prefs.setDouble('totalBillYesterday', totalBill);
//     await prefs.setInt('numberOfInvoicesYesterday', numberOfInvoices);
//   }

//   void scheduleEndOfDayTask() {
//     final now = DateTime.now();
//     final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

//     final durationUntilEndOfDay = endOfDay.difference(now);

//     Timer(durationUntilEndOfDay, () async {
//       final totalBillToday = await _totalBillTodayController.stream.first;
//       final numberOfInvoicesToday = await _numberOfInvoicesTodayController.stream.first;
//       storeYesterdayData(totalBillToday, numberOfInvoicesToday);
//     });
//   }

//   void updateSalesDataList(List<dynamic> invoices) {
//     salesDataList = [
//       SalesData('Lun', getTotalSalesForDay(invoices, DateTime.monday)),
//       SalesData('Mar', getTotalSalesForDay(invoices, DateTime.tuesday)),
//       SalesData('Mer', getTotalSalesForDay(invoices, DateTime.wednesday)),
//       SalesData('Jeu', getTotalSalesForDay(invoices, DateTime.thursday)),
//       SalesData('Ven', getTotalSalesForDay(invoices, DateTime.friday)),
//       SalesData('Sam', getTotalSalesForDay(invoices, DateTime.saturday)),
//       SalesData('Dim', getTotalSalesForDay(invoices, DateTime.sunday)),
//     ];

//     setState(() {}); // Call setState to rebuild the widget with new data
//   }

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
//       final bill = invoice['amount'];
//       if (bill != null && bill is int) {
//         return sum + bill;
//       }
//       return sum;
//     });
//   }

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
//                     Card(
//                       child: Container(
//                         height: 50,
//                         width: 50,
//                         child: IconButton(
//                           onPressed: () {
//                             showModalBottomSheet(
//                               backgroundColor: Colors.transparent,
//                               useSafeArea: true,
//                               context: context,
//                               builder: (context) {
//                                 return Container(
//                                   decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(20),
//                                       color: Colors.white),
//                                   child: const UserPage(),
//                                 );
//                               },
//                             );
//                           },
//                           icon: const Icon(Icons.person),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 Center(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     syncInvoices(context); // Appel de la fonction de synchronisation
//                   },
//                   child: Text('Synchroniser les factures'),
//                 ),
//               ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     StreamBuilder<double>(
//                       stream: _totalBillTodayController.stream,
//                       builder: (context, snapshot) {
//                         if (snapshot.hasData) {
//                           return Padding(
//                             padding: const EdgeInsets.only(left: 15.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                  AppText(text: 'TOTAL VENTE AUJOURD\'HUI'),
//                                 AppTextLarge(
//                                   text: 'Fc ${snapshot.data!.toStringAsFixed(2)}',
//                                   size: 20,
//                                 ),
//                               ],
//                             ),
//                           );
//                         } else {
//                           return const Text('chargement ...');
//                         }
//                       },
//                     ),
//                     StreamBuilder<int>(
//                       stream: _numberOfInvoicesTodayController.stream,
//                       builder: (context, snapshot) {
//                         if (snapshot.hasData) {
//                           return Padding(
//                             padding: const EdgeInsets.only(left: 15.0, right: 10),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                  AppText(text: 'Tickets'),
//                                 AppTextLarge(
//                                   text: snapshot.data.toString(),
//                                   size: 20,
//                                 ),
//                               ],
//                             ),
//                           );
//                         } else {
//                           return const Text('chargement ...');
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//                 sizedbox,
//                  Padding(
//                   padding: EdgeInsets.only(left: 15.0),
//                   child: AppText(text: 'VENTE DEJA ENREGISTRE'),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildStatContainer(context, 'Hier:', totalBillYesterday, '$numberOfInvoicesYesterday Tck'),
//                     _buildStatContainer(context, 'Mois denier:', totalBillLastMonth, '$numberOfInvoicesLastMonth Tck'),
//                   ],
//                 ),
//                 sizedbox,
//                  Padding(
//                   padding: EdgeInsets.only(left: 15.0, bottom: 10),
//                   child: AppText(text: 'VENTE SEMAINE'),
//                 ),
//                 SfCartesianChart(
                  
//                   primaryXAxis: const CategoryAxis(
//                     labelStyle: TextStyle(fontSize: 10),
//                   ),
//                   primaryYAxis: NumericAxis(
//                     labelStyle: const TextStyle(fontSize: 10),
//                     numberFormat: NumberFormat.compact(),
//                   ),
//                   series: <ColumnSeries<SalesData, String>>[
//                     ColumnSeries<SalesData, String>(
//                       color: Colors.blue.shade300,
//                       dataSource: salesDataList,
//                       xValueMapper: (SalesData sales, _) => sales.year,
//                       yValueMapper: (SalesData sales, _) => sales.sales,
//                       isTrackVisible: true,
//                       borderRadius: BorderRadius.circular(10),
//                     )
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.blue.shade300,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(30),
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

//   Widget _buildStatContainer(BuildContext context, String period, double sales, String billets) {
//     return Container(
//       height: 100,
//       width: MediaQuery.of(context).size.width * 0.45,
//       margin: const EdgeInsets.only(top: 10.0),
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade300,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: <Widget>[
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               AppTextLarge(
//                 color: Colors.white,
//                 text: period,
//                 size: 16,
//               ),
//               AppText(
//                 text: billets,
//               ),
//             ],
//           ),
//           AppTextLarge(
//             text: 'Fc ${sales.toStringAsFixed(2)}',
//             size: 18,
//             color: Colors.white,
//           ),
//         ],
//       ),
//     );
//   }
//   Future<void> syncInvoices(BuildContext context) async {
//   try {
//     await _invoiceSyncService.syncPendingInvoices();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Synchronisation réussie !')),
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Erreur lors de la synchronisation : $e')),
//     );
//   }
// }

// }

// class SalesData {
//   SalesData(this.year, this.sales);

//   final String year;
//   final double sales;
// }

