
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Калькулятор выслуги лет',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: ServiceCalculator(toggleTheme: _toggleTheme, isDark: _isDarkMode),
    );
  }
}

class ServiceCalculator extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;

  ServiceCalculator({required this.toggleTheme, required this.isDark});

  @override
  _ServiceCalculatorState createState() => _ServiceCalculatorState();
}

class _ServiceCalculatorState extends State<ServiceCalculator> {
  List<_Period> _periods = [];

  void _addPeriod() {
    setState(() {
      _periods.add(_Period());
    });
  }

  void _removePeriod(int index) {
    setState(() {
      _periods.removeAt(index);
    });
  }

  void _reset() {
    setState(() {
      _periods.clear();
    });
  }

  String _calculate() {
    int totalDays = 0;
    for (var p in _periods) {
      if (p.start != null && p.end != null && p.end!.isAfter(p.start!)) {
        final diff = p.end!.difference(p.start!).inDays;
        totalDays += (diff * p.coeff).round();
      }
    }
    final years = totalDays ~/ 365;
    final months = (totalDays % 365) ~/ 30;
    final days = (totalDays % 365) % 30;
    return "$years лет $months мес. $days дн.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Калькулятор выслуги лет'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.toggleTheme,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _periods.length,
                itemBuilder: (context, index) {
                  final p = _periods[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: p.start ?? DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        p.start = picked;
                                      });
                                    }
                                  },
                                  child: Text(p.start == null
                                      ? "Начало"
                                      : "${p.start!.toLocal()}".split(' ')[0]),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: p.end ?? DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        p.end = picked;
                                      });
                                    }
                                  },
                                  child: Text(p.end == null
                                      ? "Конец"
                                      : "${p.end!.toLocal()}".split(' ')[0]),
                                ),
                              ),
                              DropdownButton<double>(
                                value: p.coeff,
                                items: [1, 1.5, 2, 3]
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text("x$e")))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    p.coeff = val!;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _removePeriod(index),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Text(
              "Итог: ${_calculate()}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addPeriod,
                    child: Text("+ Период"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _reset,
                    child: Text("Сбросить"),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Period {
  DateTime? start;
  DateTime? end;
  double coeff = 1.0;
}
