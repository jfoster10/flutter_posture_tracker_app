import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

class FileService{

  // Placeholder data
  List<List<dynamic>> initialData = [
    [1,2,3],
    [4,5,6],
    [7,8,9]
  ];

  // Helper to get the default directory containing CSV files
  Future<String> get _localPath async{
    final directory = await getApplicationDocumentsDirectory();
    
    return directory.path;
  }

  // Write a matrix to a CSV file
  Future<File> writeCsv(List<List<dynamic>> input, String fileName) async {
    final path = await _localPath;
    final file = File('$path/$fileName.csv');
    
    final csvString = csv.encode(input);

    return await file.writeAsString(csvString, flush: true);
  }

  // Identify all CSV files in directory
  Future<List<String>> checkFiles() async{
    List<String> files = [];
    final path = await _localPath;
    final directory = Directory(path);

    for(var entity in directory.listSync()){
      if(entity is File){
        String filename = p.basename(entity.path);
        if(filename.endsWith(".csv")){
          files.add(filename);
        }
      }
    }
    return files;
  }
  
  // Read data from an existing CSV file
  Future<List<List<dynamic>>> readCsv(String fileName) async {
    final path = await _localPath;
    final file = File('$path/$fileName');
    print(file);

    try{
      final List<List<dynamic>> rows = await file.openRead().transform(utf8.decoder).transform(csv.decoder).toList();

      return rows;
    } catch (e) {
      return [["error"]];
    }
  }

  // Outdated write function.
  Future<File> writeFile(int counter, String fileName) async {
    final path = await _localPath;
    final file = File('$path/$fileName.csv');

    // Write the file
    return file.writeAsString('$counter');
  }

  // Outdated read function.
  Future<int> readFile(String fileName) async {
    try {
      final path = await _localPath;
      final file = File('$path/$fileName.txt');

      // Read the file
      final contents = await file.readAsString();

        return int.parse(contents);
      } catch (e) {
      // If encountering an error, return 0
      return 0;
    }
  }


  Future<void> deleteFile(String fileName) async {
    try {
      final path = await _localPath;
      final file = File('$path/$fileName');

      // Read the file
      file.delete();
    } on PathNotFoundException{
      print("Oops, not a valid path.");
    } catch (e) {
      print("File deletion error: $e");
    }
  }
}