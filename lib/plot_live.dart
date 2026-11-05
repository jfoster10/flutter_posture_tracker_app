//import 'dart:io';
//import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'file_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'plot.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Initial class
class PlotLive extends StatefulWidget {

  final BluetoothDevice device;
  const PlotLive({super.key, required this.device});

  @override
  State<PlotLive> createState() => _PlotLiveState();
}


// State class
class _PlotLiveState extends State<PlotLive> {

  //late Future<List<List<dynamic>>> _readCsv;

  // UUIDs to identify correct device
  static const String SERVICE_UUID = "773e4aa5-3116-408a-b924-6b3af2a81781";
  static const String CHARACTERISTIC_UUID = "43556883-b7ea-4113-a283-29b271092689";

  // Define Bluetooth Subscription
  StreamSubscription<List<int>>? _valueSubscription;

  // rowData = ALL received data | latestData = most recent row | StreamController = broadcast last ten rows of rowData via graphs
  List<List<dynamic>> rowData = [];
  List<List<dynamic>> latestData = [];
  final StreamController<List<List<dynamic>>> csvStreamController = StreamController<List<List<dynamic>>>.broadcast();

  final fileService = FileService();
  final String filename = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-');  // The file name is the time of the current session


  @override
  void initState(){
    super.initState();
    //_readCsv = fileService.readCsv(file);
    _startListeningToFeed();
  }

  Future<void> _startListeningToFeed() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/$filename.csv');

    try {
      // Discover all services on the connected device
      List<BluetoothService> services = await widget.device.discoverServices();

      // Find the service
      BluetoothService targetService = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase(),
      );

      // Find desired characteristic inside that service
      BluetoothCharacteristic targetCharacteristic = targetService.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == CHARACTERISTIC_UUID.toLowerCase(),
      );

      // Enable notifications (tells ESP32 to start streaming data)
      await targetCharacteristic.setNotifyValue(true);

      // !!!Listen to live data stream!!!
      _valueSubscription = targetCharacteristic.lastValueStream.listen((value) {
        String strRow = utf8.decode(value);
        var rawRow = csv.decode(strRow).first;
        List<dynamic> csvRow = List<dynamic>.from(
          rawRow.map<dynamic>((item) => double.tryParse(item.toString()) ?? 0.0) // (item.toString())
        );
        //List<dynamic>.from

        // ROW LAYOUT: 0=Index 1=Pitch1 2=Roll1 3=Pitch2 4=Roll2 5=PitchDiff 6=RollDiff
        // Adding: 7=FullPitch 8=FullRoll 9=FullCurvature 10=Position(string)
        csvRow.add(((csvRow[1] as num) + (csvRow[3] as num))/2);          // FullPitch
        csvRow.add((csvRow[2]+csvRow[4])/2);          // FullRoll
        csvRow.add(sqrt(pow(csvRow[5], 2) + pow(csvRow[6],2)));  // FullCurvature

        const threshold = 10;
        switch((csvRow[7], csvRow[8], csvRow[9].abs())){
          case( >= -threshold && <= threshold, >= -threshold && <= threshold, <= threshold):
            csvRow.add("straight");
          case( >= -threshold && <= threshold, >= -threshold && <= threshold, > threshold):
            csvRow.add("relaxed");
          case( > threshold, _, <= threshold):
            csvRow.add("forward_lean");
          case( > threshold, _, > threshold):
            csvRow.add("forward_hunch");
          case( < -threshold, _, <= threshold):
            csvRow.add("backward_lean");
          case( < -threshold, _, > threshold):
            csvRow.add("backward_slouch");
          case( >= -threshold && <= threshold, > threshold, <= threshold):
            csvRow.add("right_side_lean");
          case( >= -threshold && <= threshold, > threshold, > threshold):
            csvRow.add("right_side_slouch");
          case( >= -threshold && <= threshold, < -threshold, <= threshold):
            csvRow.add("left_side_lean");
          case( >= -threshold && <= threshold, < -threshold, > threshold):
            csvRow.add("left_side_slouch");
          default:
            csvRow.add("unknown");
        }


        // Write this row to file
        String csvRowString = '${csv.encode([csvRow])}\n';
        file.writeAsStringSync(csvRowString, mode: FileMode.append, flush: true);

        print("Row: $csvRow");
        setState(() {
          rowData.add(csvRow);

          if(rowData.length >= 10){
            latestData = rowData.sublist(rowData.length - 10, rowData.length);
          }
          else{
            latestData = rowData;
          }

          csvStreamController.add(latestData);
        });
        print('Received live data bytes: $value');
      });

    } catch (e) {
      print('Error setting up feed listener: $e');
    }
  }

  @override
  void dispose() {
    // Clean up: cancel stream and stop notifications when leaving the screen
    _valueSubscription?.cancel();
    widget.device.disconnect();
    csvStreamController.close(); //testing
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Feed: ${widget.device.platformName}'),
        backgroundColor: Colors.tealAccent
      ),

      body: Center(
        child: Column(
          children: [
            Text("Pitch (red=IMU#1, blue=IMU#2, purple=Difference):"),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<List<dynamic>>>(
                stream: csvStreamController.stream,
                builder: (context, snapshot) {
                  if(snapshot.hasData && snapshot.data is List<List<dynamic>>){
                    final validRows = snapshot.data!.where((row) => row.length > 2);
                    
                    final x_data = validRows.map((row) => row[0]).toList(); // Frame Number
                    final y_data1 = validRows.map((row) => row[1]).toList(); // Pitch1
                    final y_data2 = validRows.map((row) => row[3]).toList(); // Pitch2
                    final y_data3 = validRows.map((row) => row[5]).toList(); // Difference
                    final title_data = validRows.map((row) => row[10]).toList();

                    final points1 = List.generate(
                      x_data.length,
                      (i) => FlSpot(
                        x_data[i],
                        // double.parse()
                        y_data1[i],
                      ),
                    );

                    final points2 = List.generate(x_data.length, (i) =>
                      FlSpot(
                        x_data[i],
                        y_data2[i],
                      ),
                    );

                    final points3 = List.generate(x_data.length, (i) =>
                      FlSpot(
                        x_data[i],
                        y_data3[i],
                      ),
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: LineChart(
                            LineChartData(
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
                          ),
                        ),
                        Text("Current Position: ${title_data.last}"),
                      ],
                    );
                    
                  }
                  else {return CircularProgressIndicator();}
                }
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Text("Roll (red=IMU#1, blue=IMU#2, purple=Difference):"),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<List<dynamic>>>(
                stream: csvStreamController.stream,
                builder: (context, snapshot) {
                  if(snapshot.hasData && snapshot.data is List<List<dynamic>>){
                    final validRows = snapshot.data!.where((row) => row.length > 2);
                    
                    final x_data = validRows.map((row) => row[0]).toList(); // Frame Number
                    final y_data1 = validRows.map((row) => row[2]).toList(); // Roll1
                    final y_data2 = validRows.map((row) => row[4]).toList(); // Roll2
                    final y_data3 = validRows.map((row) => row[6]).toList(); // Difference
                    final title_data = validRows.map((row) => row[10]).toList();

                    final points1 = List.generate(
                      x_data.length,
                      (i) => FlSpot(
                        x_data[i],
                        y_data1[i],
                      ),
                    );

                    final points2 = List.generate(x_data.length, (i) =>
                      FlSpot(
                        x_data[i],
                        y_data2[i],
                      ),
                    );

                    final points3 = List.generate(x_data.length, (i) =>
                      FlSpot(
                        x_data[i],
                        y_data3[i],
                      ),
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: LineChart(
                            LineChartData(
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
                          ),
                        ),
                        Text("Current Position: ${title_data.last}"),
                      ],
                    );
                  }
                  else {return CircularProgressIndicator();}
                }
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                //final directory = await getApplicationDocumentsDirectory();
                //final path = directory.path;
                //final fullFilePath = '$path/$filename.csv';

                if (!context.mounted) return;
                
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => Plot(passedFile: '$filename.csv'),
                  ),
                );
              },
              child: const Text('Load'),
            ),
          ],), 

      ),
    );
  }
}

