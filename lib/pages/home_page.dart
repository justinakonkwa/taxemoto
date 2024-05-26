// ignore_for_file: use_super_parameters, prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:taxaero/pages/invoice_forme.dart';
import 'package:taxaero/pages/user_page.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/app_text_large.dart';
import 'package:taxaero/widget/constantes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    AppTextLarge(
                      text: 'Taxe Moto',
                      size: 40,
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPage(),
                          ),
                        );
                      },
                      child: Card(
                        child: Container(
                          height: 40,
                          width: 40,
                          child: Icon(
                            Icons.person,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(text: 'TOTAL VENTE AUJOURD\'HUI'),
                      AppTextLarge(
                        text: 'Fc 2500',
                        size: 20,
                      ),
                    ],
                  ),
                ),
                sizedbox,
                Container(
                  padding: EdgeInsets.all(10),
                  height: 300.0,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue.shade100),
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    series: <ColumnSeries<SalesData, String>>[
                      ColumnSeries<SalesData, String>(
                        dataSource: <SalesData>[
                          SalesData('lund', 35),
                          SalesData('Mard', 28),
                          SalesData('Merc', 34),
                          SalesData('Jeud', 52),
                          SalesData('Vend', 40),
                          SalesData('Sam', 51),
                          SalesData('Dim', 45),
                        ],
                        xValueMapper: (SalesData sales, _) => sales.year,
                        yValueMapper: (SalesData sales, _) => sales.sales,
                        isTrackVisible: true,
                        borderRadius: BorderRadius.circular(10),
                      )
                    ],
                  ),
                ),
                sizedbox,
                Container(
                    margin: EdgeInsets.only(left: 15.0),
                    child: AppText(text: 'STATISTIQUE')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatContainer(context, 'Hier:', 7500, '15 Tck'),
                    _buildStatContainer(
                        context, 'Mois Passé:', 855000, '125 Tck'),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditTaxFormPage(),
            ),
          );
        },
        child: const Icon(Icons.note_add),
      ),
    );
  }

  Widget _buildStatContainer(
      BuildContext context, String period, double sales, String billets) {
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.45,
      margin: EdgeInsets.only(top: 10.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: period,
              ),
              AppText(
                text: billets,
              ),
            ],
          ),
          AppTextLarge(
            text: '\ Fc ${sales.toStringAsFixed(2)}',
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
