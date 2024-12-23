import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_seek_slider/time_seek_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeSeekSlider demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'TimeSeekSlider Package demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool _isPlaying = false;
  // selected Date.
  DateTime _selectedTime = DateTime(2024,6,1,13,30);
  // selecting Date by drag bar
  DateTime _selectingTime = DateTime(2024,6,1,13,30);
  // term.
  final DateTime _from = DateTime(2024,6,1,12,0);
  final DateTime _to = DateTime(2024,6,1,14,0);
  
  int _sectionTime = TimeSeekSlider.sectionHour;

  final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');


  @override
  void initState() {
    super.initState();

    _startTimer();
  }

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying) {
        setState(() {
          if (_sectionTime < TimeSeekSlider.sectionMinute) {
            _selectedTime = _selectedTime.add(const Duration(seconds: 1));
          } else if (_sectionTime < TimeSeekSlider.sectionHour) {
              _selectedTime = _selectedTime.add(const Duration(seconds: 10));
          } else if (_sectionTime < TimeSeekSlider.section3Hours) {
            _selectedTime = _selectedTime.add(const Duration(minutes: 10));
          } else if (_sectionTime < TimeSeekSlider.section12Hours) {
            _selectedTime = _selectedTime.add(const Duration(minutes: 30));
          } else {
            _selectedTime = _selectedTime.add(const Duration(hours: 1));
          }
          //print('[TimeSeekSlider] Current: ${formatter.format(_selectedTime)}');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    //print('[MyHomePage.build] Enter');

    // Layer 0
    List<TimePeriod> timePeriods0 = [];
    for(int i=0; i < 10; i++) {
      timePeriods0.add(TimePeriod(
          DateTime(2024, 6, 1,13,00,0).add(Duration(minutes: 40*i)),
          DateTime(2024, 6, 1,13,30,0).add(Duration(minutes: 40*i))
      ));
    }
    // Layer 1
    List<TimePeriod> timePeriods1 = [];
    for(int i=0; i < 100; i++) {
      timePeriods1.add(TimePeriod(
          DateTime(2024, 6, 1,13,00,0).add(Duration(minutes: 10*i)),
          DateTime(2024, 6, 1,13,05,0).add(Duration(minutes: 10*i))
      ));
    }
    // Layer 2
    List<TimePeriod> timePeriods2 = [];
    for(int i=0; i < 100; i++) {
      timePeriods2.add(TimePeriod(
          DateTime(2024, 6, 1,13,00,0).add(Duration(minutes: 10*i)),
          DateTime(2024, 6, 1,13,00,0).add(Duration(minutes: 10*i))
      ));
    }
    // 追加した順に描画される（後上書き）.
    List<TimeEvent> timeEvents = [];
    timeEvents.add(TimeEvent(20, Colors.yellow, timePeriods0));
    timeEvents.add(TimeEvent(10, Colors.green, timePeriods1));
    timeEvents.add(TimeEvent(70, Colors.black, timePeriods2));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selected : ${formatter.format(_selectedTime)}'),
              Text('Dragging : ${formatter.format(_selectingTime)}'),
              SizedBox(
                // width: 300,
                height: 80,
                child:Container(
                  decoration: BoxDecoration(
                    color: const Color(0x00000000),
                    border: Border.all(
                      color: Colors.blue[900]!,
                      width: 1.0,
                    ),
                  ),
                  child: TimeSeekSlider(
                    fixedTerm: true,
                    from: _from,
                    to: _to,
                    selectedTime: _selectedTime,
                    sectionTime: _sectionTime,
                    sectionWidth: 100,
                    timeTextColor: Colors.indigo,
                    sectionColorPrimery: Colors.blue[50],
                    sectionColorSecondary: Colors.blue[100],
                    centerLineColor: Colors.blueAccent,
                    showCurrentTime: ShowCurrentTime.showDuringDragging,
                    currentTimeTextColor: Colors.white,
                    currentTimeTextBackgroundColor: Colors.blue,
                    events: timeEvents,
                    onChangingSelectedTime: (time) {
                      // print('[onChangingSelectedTime] time=${formatter.format(time)}');
                      setState(() {
                        _selectingTime = time;
                      });
                    },
                    onChangedSelectedTime: (time) {
                      // print('[onChangedSelectedTime] time=${formatter.format(time)}');
                      setState(() {
                        _selectedTime = time;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10,),
              SectionTimeChoice(
                onSelectionChanged: (selection) {
                  setState(() {
                    _sectionTime = selection;
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                  child: Icon(_isPlaying ? Icons.stop : Icons.play_arrow)
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class SectionTimeChoice extends StatefulWidget {
  const SectionTimeChoice({super.key, this.onSelectionChanged});

  final Function(int)? onSelectionChanged;

  @override
  State<SectionTimeChoice> createState() => _SectionTimeChoiceState();
}

class _SectionTimeChoiceState extends State<SectionTimeChoice> {
  int selectedRecordType = TimeSeekSlider.sectionHour;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const <ButtonSegment<int>>[
        ButtonSegment<int>(
          value: TimeSeekSlider.section24Hours,
          label: Text('24h'),
        ),
        ButtonSegment<int>(
          value: TimeSeekSlider.section12Hours,
          label: Text('12h'),
        ),
        ButtonSegment<int>(
          value: TimeSeekSlider.section3Hours,
          label: Text('3h'),
        ),
        ButtonSegment<int>(
          value: TimeSeekSlider.sectionHour,
          label: Text('1h'),
        ),
        ButtonSegment<int>(
          value: TimeSeekSlider.section10Minute,
          label: Text('10m'),
        ),
        ButtonSegment<int>(
          value: TimeSeekSlider.sectionMinute,
          label: Text('1m'),
        ),
        ButtonSegment<int>(
          value: TimeSeekSlider.section30Seconds,
          label: Text('30s'),
        ),
        ButtonSegment<int>(
          value: TimeSeekSlider.section10Seconds,
          label: Text('10s'),
        ),
      ],
      selected: <int>{selectedRecordType},
      showSelectedIcon: false,
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          selectedRecordType = newSelection.first;
        });
        widget.onSelectionChanged!(selectedRecordType);
      },
    );
  }
}
