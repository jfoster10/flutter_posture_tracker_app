import 'package:flutter/material.dart';
import 'file_service.dart';
import 'plot.dart';


class SecondRoute extends StatefulWidget {
  const SecondRoute({super.key});

  @override
  State<SecondRoute> createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {

  final fileService = FileService();
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Route'),
        backgroundColor: Colors.tealAccent
        ),
      body: Center(
        child: Column(
          spacing: 20,
          children: [
             Expanded(
                child: FutureBuilder(
                  future: fileService.checkFiles(),
                  builder: (context, snapshot){

                    if(!snapshot.hasData) return CircularProgressIndicator();

                    return ListView(
                      children: snapshot.data!.map((file) => ListTile(
                        title: Text(file),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) => Plot(passedFile: file),
                                  ),
                                );
                              },
                              child: const Text('Load'),
                              /*
                                final value = await fileService.readCsv("test_filename");
                                print("Loaded: $value");
                              },
                              */
                            ),
                             ElevatedButton(
                              onPressed: () async {
                                await fileService.deleteFile(file);
                                if(mounted){
                                  setState((){});
                                }
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                          
                      )).toList(),
                    );
                  }
                ),
              ),

            const Text("Yo wassup my guy please enter a file name or smth"),


            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.5,
              child: TextField(
                textAlign: TextAlign.center,
                obscureText: false,

                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter a name for a new file to save to",
                ),

                onSubmitted: (String value) async {
                  await fileService.writeCsv(fileService.initialData, value);
                },
              ),
            ),

            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.5,
              child: TextField(
                textAlign: TextAlign.center,
                obscureText: false,

                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter a name for a file to load from",
                ),

                onSubmitted: (String title) async {
                  final output = await fileService.readCsv(title);
                  print("Loaded: $output");
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 100,
              children: [
                ElevatedButton(
                  onPressed: () async{
                  // Navigate back to first route when tapped.
                  //await Future.delayed(const Duration(seconds: 2));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  },
                  child: const Text('Go back!'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    await fileService.writeCsv(fileService.initialData, "test_filename");
                    print("Saved data");
                  },
                  child: const Text('Save data'),
                ),

                
                ],
              ),
          ]
        ),
      ),
    );
  }
}