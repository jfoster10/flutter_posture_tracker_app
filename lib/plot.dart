import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'file_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'analyze.dart';

// Helper function for transposing a matrix
List<List<dynamic>> transpose(List<List<dynamic>> matrix) {
  if (matrix.isEmpty || matrix[0].isEmpty) return [];
  
  int rowCount = matrix.length;
  int colCount = matrix[0].length;

  return List.generate(colCount, (c) {
    return List.generate(rowCount, (r) {
      return matrix[r][c];
    });
  });
}


class Plot extends StatefulWidget {

  final String passedFile;
  const Plot({super.key, required this.passedFile});

  @override
  State<Plot> createState() => _PlotState();
}

class _PlotState extends State<Plot> {

  late String file;
  Future<List<List<dynamic>>>? readCsv;

  final fileService = FileService();

  @override
  void initState(){
    super.initState();
    file = widget.passedFile;
    readCsv = fileService.readCsv(file);
    initFile();
  }

  // Async initialization of file
  void initFile() async {
    try{
      final directory = await getApplicationDocumentsDirectory();
      final resolvedFileObject = File('${directory.path}/$file');
      if (resolvedFileObject.existsSync()) {
        print("File size on page entry: ${resolvedFileObject.lengthSync()} bytes");
      }
    } catch(e) {
      print("Error in metrics: $e");
    }
    /*
    final directory = await getApplicationDocumentsDirectory();
    
    // Path checking
    final filename = file.endsWith('.csv') ? file : '$file.csv';
    final resolvedFile = File('${directory.path}/$filename');

    print("File size on page entry: ${resolvedFile.lengthSync()} bytes");

    // Read file
    setState(() {
      readCsv = fileService.readCsv(filename);
    });*/
  }
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Plotting page: $file'),
        backgroundColor: Colors.tealAccent
      ),

      body: SingleChildScrollView(
        child: Column(
          spacing: 20,
          children: [
            Text("Foward/Backward Lean (red=IMU#1, blue=IMU#2, purple=Difference):"),
            SizedBox(
              height: 200,
              child: FutureBuilder(
                future: readCsv,
                builder: (context, snapshot) {
                  if(snapshot.hasData && snapshot.data is List<List<dynamic>>){
                    final validRows = snapshot.data!.where((row) => row.length > 2);

                    final x_data = validRows.map((row) => row[0]).toList(); // Frame Number
                    final y_data1 = validRows.map((row) => row[1]).toList(); // Pitch1
                    final y_data2 = validRows.map((row) => row[3]).toList(); // Pitch2
                    final y_data3 = validRows.map((row) => row[5]).toList(); // Difference

                    final points1 = List.generate(
                      x_data.length,
                      (i) => FlSpot(
                        double.parse(x_data[i]),
                        double.parse(y_data1[i]),
                      ),
                    );

                    final points2 = List.generate(x_data.length, (i) =>
                      FlSpot(
                        double.parse(x_data[i]),
                        double.parse(y_data2[i]),
                      ),
                    );

                    final points3 = List.generate(x_data.length, (i) =>
                      FlSpot(
                        double.parse(x_data[i]),
                        double.parse(y_data3[i]),
                      ),
                    );

                    return LineChart(
                      LineChartData(
                        minY: -90,
                        maxY: 90,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            strokeWidth: 1,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: points1,
                            color: Colors.red.withAlpha(100),
                            dotData: FlDotData(show: false),
                          ),
                          LineChartBarData(
                            isCurved: true,
                            spots: points2,
                            color: Colors.blue.withAlpha(100),
                            dotData: FlDotData(show: false),
                          ),
                          LineChartBarData(
                            isCurved: true,
                            spots: points3,
                            color: const Color.fromARGB(255, 229, 82, 255),
                            dotData: FlDotData(show: false),
                            barWidth: 3,
                          ),
                        ],
                      ),
                    );
                  }
                  else {return CircularProgressIndicator();}
                },
              ),
            ),

            Text("Right/Left Lean (red=IMU#1, blue=IMU#2, purple=Difference):"),
            SizedBox(
              height: 200,
              child: FutureBuilder(
                future: readCsv,
                builder: (context, snapshot) {
                  if(snapshot.hasData && snapshot.data is List<List<dynamic>>){
                    final validRows = snapshot.data!.where((row) => row.length > 2);
                    
                    final x_data = validRows.map((row) => row[0]).toList(); // Frame Number
                    final y_data1 = validRows.map((row) => row[2]).toList(); // Roll1
                    final y_data2 = validRows.map((row) => row[4]).toList(); // Roll2
                    final y_data3 = validRows.map((row) => row[6]).toList(); // Difference

                    final points1 = List.generate(
                      x_data.length,
                      (i) => FlSpot(
                        double.parse(x_data[i]),
                        double.parse(y_data1[i]),
                      ),
                    );

                    final points2 = List.generate(x_data.length, (i) =>
                      FlSpot(
                        double.parse(x_data[i]),
                        double.parse(y_data2[i]),
                      ),
                    );

                    final points3 = List.generate(x_data.length, (i) =>
                      FlSpot(
                        double.parse(x_data[i]),
                        double.parse(y_data3[i]),
                      ),
                    );

                    return LineChart(
                      LineChartData(
                        minY: -90,
                        maxY: 90,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            strokeWidth: 1,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: points1,
                            color: Colors.red,
                          ),
                          LineChartBarData(
                            isCurved: true,
                            spots: points2,
                            color: Colors.blue,
                          ),
                          LineChartBarData(
                            isCurved: true,
                            spots: points3,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    );
                  }
                  else {return CircularProgressIndicator();}
                },
              ),
            ),

            SingleChildScrollView(
              child: FutureBuilder(
                future: readCsv,
                builder: (context, snapshot) {
                  if(snapshot.hasData && snapshot.data is List<List<dynamic>>){

                    final validRows = snapshot.data!.where((row) => row.length > 2).toList();

                    /*final data = transpose(validRows);*/

                    String positionDetails1 = "";
                    String positionDetails2 = "";

                    String averageDetails1 = "";
                    String averageDetails2 = "";

                    String variationDetails = "";

                    try{
                      final analyze = Analyze(validRows);
                      analyze.getPositionCounts();
                      analyze.getPosSignificances();

                      int sig1 = analyze.mostSignificantIndex();
                      int sig2 = analyze.secondMostSignificantIndex();

                      positionDetails1 = analyze.getSignificantPosition(sig1);
                      positionDetails2 = analyze.getSignificantPosition(sig2);

                      averageDetails1 = analyze.getAverageDetails(sig1);
                      averageDetails2 = analyze.getAverageDetails(sig2);

                      variationDetails = analyze.getVariationDetails(sig1);

                    } catch(e){
                      print("Using analyze failed somehow: $e");
                    }

                    return FractionallySizedBox(
                      widthFactor:0.9,
                      
                      child: Column(children: [
                        Text(positionDetails1),
                        const SizedBox(height: 10),
                        Text(averageDetails1),
                        const SizedBox(height: 30),
                        Text(positionDetails2),
                        const SizedBox(height: 10),
                        Text(averageDetails2),
                        const SizedBox(height: 30),
                        Text(variationDetails),
                        const SizedBox(height: 100),
                      ]
                      ,), 
                    );
                  }
                  else {return CircularProgressIndicator();}
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}