import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _inputController = TextEditingController();

  List _taskList = [];
  int _lastPosition = 0;
  Map<String, dynamic> _lastRemovedTask = {};

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _taskList = json.decode(data);
      });
    });
  }

  Future<String> _readData() async {
    final dataFile = await _getFileData();
    return dataFile.readAsString();
  }

  Future<File> _saveData() async {
    String currentData = json.encode(_taskList);
    final dataFile = await _getFileData();
    return dataFile.writeAsString(currentData);
  }

  Future<File> _getFileData() async {
    final source = await getApplicationDocumentsDirectory();
    return File("${source.path}/data.json");
  }

  Future<void> _refreshContent() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _taskList.sort((left, right) {
        if (left["ok"] && !right["ok"]) {
          return 1;
        } else if (!left["ok"] && right["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });
  }

  void addTask() {
    setState(() {
      Map<String, dynamic> newTask = {};
      newTask["title"] = _inputController.text;
      _inputController.text = "";
      newTask["ok"] = false;
      _taskList.add(newTask);
      _saveData();
    });
  }

  void completeTask(index, c) {
    setState(() {
      _taskList[index]["ok"] = c;
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Tarefas'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.green),
                      hintText: "Digite algo...",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onEditingComplete: () {
                      if (_inputController.text != "") {
                        addTask();
                      }
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_inputController.text != "") {
                      addTask();
                    }
                  },
                  child: const Text("Adicionar"),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshContent,
              child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10.0), itemCount: _taskList.length, itemBuilder: getWidget),
            ),
          ),
        ],
      ),
    );
  }

  Widget getWidget(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemovedTask = Map.from(_taskList[index]);
          _lastPosition = index;
          _taskList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemovedTask["title"]} removida."),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _taskList.insert(_lastPosition, _lastRemovedTask);
                  _saveData();
                });
              },
            ),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
      child: CheckboxListTile(
        title: Text(_taskList[index]["title"]),
        value: _taskList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_taskList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          completeTask(index, c);
        },
      ),
    );
  }
}
