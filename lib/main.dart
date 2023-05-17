import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wish list',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Wish list'),
    );
  }
}

timeFormat(DateTime date) {
  return "${date.year}-${date.month<=9?"0":""}${date.month}-${date.day<=9?"0":""}${date.day}";
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Wish{
  String name;
  bool isDone;
  DateTime deadline;
  DateTime doneDate;

  Wish({required this.name, required this.isDone, required this.deadline, required this.doneDate});


  factory Wish.fromJson(Map<String, dynamic> json){
    return Wish(
      name: json['name'],
      isDone: json['isDone'],
      deadline: DateTime.parse(json['deadline']),
      doneDate: DateTime.parse(json['doneDate']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'isDone': isDone,
    'deadline': deadline.toString(),
    'doneDate': doneDate.toString(),
  };

  getDate() {
    if (isDone){
      return Text("Done: ${timeFormat(doneDate)}", style: const TextStyle(color: Colors.green),);
    } else{
      return Text("Deadline: ${timeFormat(deadline)}", style: const TextStyle(color: Colors.red));
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> wishes = <String>['Wish 1', 'Wish 2', 'Wish 3', 'Wish 4'];
  List<Wish> userWishes = <Wish>[];
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late String _dropdownValue;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _dropdownValue = wishes.first;
    _selectedDate = DateTime.now();
    _prefs.then((prefs) {
      //prefs.setStringList("userWishes", []);
      userWishes = prefs.getStringList("userWishes")!.map((wish) => Wish.fromJson(jsonDecode(wish))).toList();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.separated(
        itemCount: userWishes.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Checkbox(
                value: userWishes[index].isDone,
                onChanged: (value) => setState(() {
                  userWishes[index].isDone = !userWishes[index].isDone;
                }),
            ),
            title: Text(userWishes[index].name),
            subtitle: userWishes[index].getDate(),
            trailing: IconButton(
              onPressed: () {
                _prefs.then((prefs) {
                  var userWishesDB = prefs.getStringList("userWishes");
                  userWishesDB ??= [];
                  userWishesDB.removeAt(index);
                  prefs.setStringList("userWishes", userWishesDB);
                });

                setState(() {
                  userWishes.removeAt(index);
                });
              },
              icon: const Icon(Icons.delete),
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text("Add wish"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton(
                      value: _dropdownValue,
                      items: wishes.map((wish) => DropdownMenuItem(
                        value: wish.toString(),
                        child: Text(wish.toString()),
                      )).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _dropdownValue = value!;
                        });
                      },
                    ),
                    ElevatedButton(
                        onPressed: () async{
                          final DateTime? dataTime = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2025)
                          );

                          if(dataTime != null){
                            setState((){
                              _selectedDate = dataTime;
                            });
                          }
                        },
                        child: const Text("Choose Date")
                    ),
                    Text("Deadline: ${timeFormat(_selectedDate)}")
                  ],
                ),
                actions:<Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, "Cancel"),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, "Add");
                    },
                    child: const Text("Add"),
                  ),
                ],
              ),
            )
        ).then((value){
          if (userWishes.where((element) => element.name == _dropdownValue).isNotEmpty) {
            return;
          }

          var wish = Wish(name:_dropdownValue, isDone:  false, deadline: _selectedDate, doneDate: DateTime.now());
          _prefs.then((prefs) {
            var userWishesDB = prefs.getStringList("userWishes");
            userWishesDB ??= [];
            userWishesDB.add(jsonEncode(wish.toJson()));

            prefs.setStringList("userWishes", userWishesDB);
            setState(() {
              userWishes.add(wish);
              _selectedDate = DateTime.now();
            });
          });
        }
        ),
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
