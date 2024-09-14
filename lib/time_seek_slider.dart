library time_seek_slider;


import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
// import 'package:intl/intl.dart';

class TimeSeekSlider extends StatefulWidget {
  const TimeSeekSlider({
    super.key,
    required this.selectedTime,
    this.fixedTerm = false,
    this.from,
    this.to,
    this.sectionTime = sectionHour,
    this.sectionWidth = 120,
    this.timeTextColor,
    this.sectionColorPrimery,
    this.sectionColorSecondary,
    this.centerLineColor,
    this.showCurrentTime,
    this.currentTimeTextColor,
    this.currentTimeTextBackgroundColor,
    this.events,
    required this.onChangedSelectedTime,
    this.onChangingSelectedTime,
  });

  /// Selected DateTime.
  final DateTime selectedTime;
  /// Whether the term is fixed or not.
  final bool fixedTerm;
  /// Start DateTime of Slider.
  final DateTime? from;
  /// End DateTime of Slider.
  final DateTime? to;


  /// Time span of one section.
  ///
  /// Available values are below:
  ///  - [sectionMinute]
  ///  - [section10Minute]
  ///  - [sectionHour]
  ///  - [section3Hours]
  ///  - [section12Hours]
  ///  - [section24Hours]
  final int sectionTime;

  /// Width (px) of one section.
  ///
  /// Width should be larger than width of 5 letters.
  final int sectionWidth;

  /// Color of time text.
  final Color? timeTextColor;

  /// Color of primery section.
  ///
  /// Set both of [sectionColorPrimery] and [sectionColorSecondary]
  /// if you want to define the colors.
  final Color? sectionColorPrimery;

  /// Color of secondary section.
  ///
  /// Set both of [sectionColorPrimery] and [sectionColorSecondary]
  /// if you want to define the colors.
  final Color? sectionColorSecondary;

  /// Color of center line
  final Color? centerLineColor;

  /// Show current time over center line
  final ShowCurrentTime? showCurrentTime;

  /// Color of current time Text
  final Color? currentTimeTextColor;
  final Color? currentTimeTextBackgroundColor;

  /// List of events.
  ///
  /// Events can be drawn on sliders.
  /// Multiple events can be specified as an array, and the arrays will be
  /// drawn one on top of the other in ascending order.
  /// A single event can have a height, color, and multiple terms.
  final List<TimeEvent>? events;

  /// Callback function when selected DateTime is changed.
  final Function(DateTime) onChangedSelectedTime;

  /// Callback function when selected DateTime is changing by drag.
  final Function(DateTime)? onChangingSelectedTime;

  /// Available values of sectionTime.
  static const int sectionMinute    = 60;
  static const int section10Minute  = 600;
  static const int sectionHour      = 3600;
  static const int section3Hours    = 3600 * 3;
  static const int section12Hours   = 3600 * 12;
  static const int section24Hours   = 3600 * 24;

  @override
  TimeSeekSliderState createState() => TimeSeekSliderState();
}

class TimeSeekSliderState extends State<TimeSeekSlider> {

  // Key of ListView Widget.
  final _widgetKey = GlobalKey();

  // Selected DateTime in local widget.
  var _currentTime = DateTime.now();
  // Dragging DateTime
  var _draggingTime = DateTime.now();
  // Start DateTime of this widget.
  // var _periodStart = DateTime.now().subtract(const Duration(hours: 12));
  // End DateTime of this widget.
  var _periodEnd = DateTime.now().add(const Duration(hours: 8));

  var _scrollLimitFrom = DateTime.now().subtract(const Duration(hours: 8));
  var _scrollLimitTo = DateTime.now().add(const Duration(hours: 8));

  // Width of this widget.
  double _width = 0.0;
  // Height of this widget.
  double _height = 0.0;
  // Offset position for calculate selected DateTime.
  double _offset = 0.0;
  // num of sections in ListView.
  int _numSections = 10;

  // ScrollController for ListView
  final ScrollController _scrollController = ScrollController();
  bool _isAddedScrollListener = false;
  bool _isScrollingListener = false;

  // Whether user is dragging the ListView or not.
  bool _isScrolling = false;


  @override
  void initState() {
    super.initState();

    // Add ScrollController to ListView.
    _scrollController.addListener(_scrollListener);

    _currentTime = widget.selectedTime;
    _draggingTime = _currentTime;
    // set period end to (current time + 10 sections).
    _periodEnd = _calcPeriod(_currentTime.add(Duration(seconds: widget.sectionTime * _numSections)));
    // set available period of ListView.
    _scrollLimitFrom = _calcPeriod(_currentTime.subtract(Duration(seconds: widget.sectionTime * _numSections)));
    _scrollLimitTo = _calcPeriod(_periodEnd.subtract(Duration(seconds: widget.sectionTime * (_numSections ~/ 2) + 1)));

    // Set listener of drag ListView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dragListener();
    });
  }

  @override
  void didUpdateWidget(covariant TimeSeekSlider oldWidget) {

    _currentTime = widget.selectedTime;

    // Update the term of ListView because sectionTime was changed.
    if (oldWidget.sectionTime != widget.sectionTime) {
      //print('[didUpdateWidget] sectionTime changed.');
      _currentTime = widget.selectedTime;
      // set period end to (current time + 10 sections).
      _periodEnd = _calcPeriod(_currentTime.add(Duration(seconds: widget.sectionTime * _numSections)));
      // set available period of ListView.
      _scrollLimitFrom = _calcPeriod(_currentTime.subtract(Duration(seconds: widget.sectionTime * _numSections)));
      _scrollLimitTo = _calcPeriod(_periodEnd.subtract(Duration(seconds: widget.sectionTime * (_numSections ~/ 2) + 1)));
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Adjust the time Considering the duration of section.
  /// @param time input time.
  /// @return adjusted time.
  DateTime _calcPeriod(DateTime time) {
    if (widget.sectionTime == TimeSeekSlider.section10Minute) {
      return DateTime(time.year, time.month, time.day, time.hour, time.minute ~/ 10 * 10, 0);
    } else if (widget.sectionTime == TimeSeekSlider.section24Hours) {
      return DateTime(time.year, time.month, time.day, 0, 0, 0);
    } else if (widget.sectionTime == TimeSeekSlider.sectionHour) {
      return DateTime(time.year, time.month, time.day, time.hour, 0, 0);
    } else if (widget.sectionTime == TimeSeekSlider.section3Hours) {
      return DateTime(time.year, time.month, time.day, time.hour ~/3 * 3, 0, 0);
    } else if (widget.sectionTime == TimeSeekSlider.section12Hours) {
      return DateTime(time.year, time.month, time.day, time.hour ~/12 * 12, 0, 0);
    } else if (widget.sectionTime == TimeSeekSlider.sectionMinute) {
      return DateTime(time.year, time.month, time.day, time.hour, time.minute, 0);
    }
    return DateTime(time.year, time.month, time.day, time.hour, time.minute, time.second);
  }

  /// Calculate the position in ListView from DateTime.
  /// @param time DateTime.
  /// @return position (px) in ListView.
  double _getSelectedPosition(DateTime time) {
    // get difference from end of term.
    var diff = _periodEnd.difference(time);
    // Calc the position in ListView.
    var centerPos = widget.sectionWidth * diff.inSeconds / widget.sectionTime;
    //print('[_getSelectedPosition] diff=${diff.inSeconds}s ${diff.inMinutes}m ${diff.inHours}h , center=$centerPos');
    return centerPos;
  }

  /// Calculate the time from the position in ListView.
  /// Real End = periodEnd + widget.sectionTime.
  /// @param pos position in ListView.
  /// @return DateTime.
  DateTime _getSelectedTimeFromPosition(double pos) {
    var sec = pos / widget.sectionWidth * widget.sectionTime;
    var newTime = _periodEnd.subtract(Duration(seconds: sec.toInt() - widget.sectionTime));
    //print('[_getSelectedTimeFromPosition] ${DateFormat('yyyy-MM-dd HH:mm:ss').format(newTime)}');
    return newTime;
  }

  ///  Scroll to the specific position.
  /// @param position the right of ListView.
  void _scrollToPosition(double position) {
    // use schedulePostFrameCallback of WidgetsBinding to get original size.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(position + _offset);
    });
  }

  /// Listener when ListView was scrolled.
  void _scrollListener() {
    //print('[_scrollListener] Enter');

    if (_scrollController.position.userScrollDirection == ScrollDirection.idle) {
      // _isScrolling = false;
    } else {
      // Reset the flag of scrolling.
      _isScrolling = true;
      // Calculate the center position of ListView.
      double pos = _scrollController.position.pixels + _width / 2;
      //print('[_scrollListener] Center Pos: $pos px , Right Pos: ${_scrollController.position.pixels} px');
      // Get the time of this position.
      var newTime = _getSelectedTimeFromPosition(pos);

      // Check the time is in the fixed term.
      if (widget.fixedTerm && widget.from != null && widget.to != null) {
        if (newTime.isBefore(widget.from!)) {
          newTime = widget.from!;
        } else if (widget.to!.isBefore(newTime)) {
          newTime = widget.to!;
        }
      }
      _currentTime = newTime;
      _draggingTime = newTime;

      // Notify the position changing by drag to the parent widget.
      if (widget.onChangingSelectedTime != null) {
        widget.onChangingSelectedTime!(_draggingTime);
      }
    }
  }

  /// Set listener of drag ListView
  void _dragListener() {
    // Add Listener to check scrolling.
    if (_isAddedScrollListener == false) {
      _scrollController.position.isScrollingNotifier.addListener(() {
        if (_isScrollingListener == false && _scrollController.position.isScrollingNotifier.value == true) {
          // Start scrolling.
          _isScrollingListener = true;
          _isScrolling = true;
          // print('[isScrollingNotifier] Scrolling: $_isScrolling');
        }
        else if (_isScrollingListener == true && _scrollController.position.isScrollingNotifier.value == false) {
          // End scrolling.
          setState(() {
            _isScrollingListener = false;
            _isScrolling = false;
          });
          // print('[isScrollingNotifier] Scrolling: $_isScrolling');
          // Notify the position changed to the parent widget.
          widget.onChangedSelectedTime(_draggingTime);
        }
        //print('[isScrollingNotifier] _isScrollingListener: $_isScrollingListener');
      });
      _isAddedScrollListener = true;
    }
  }

  /// Calculate the position and notify the changed when ListView was tapped.
  void _onTapSlider(double dx) {
    // Calculate the tapped position
    double pos = _scrollController.position.pixels + _width - dx;
    //print('[_scrollListener] Tap Pos: $pos px , Right Pos: ${_scrollController.position.pixels} px');
    // Get the time from position.
    var newTime = _getSelectedTimeFromPosition(pos);

    // Check the time is in the fixed term.
    if (widget.fixedTerm && widget.from != null && widget.to != null) {
      if (newTime.isBefore(widget.from!)) {
        newTime = widget.from!;
      } else if (widget.to!.isBefore(newTime)) {
        newTime = widget.to!;
      }
    }
    _currentTime = newTime;
    _draggingTime = newTime;

    // Notify the position changed to the parent widget.
    widget.onChangedSelectedTime(newTime);
  }

  /// Get the background color of the section starting at the specified time.
  /// Prevent the color of the same time period from changing depending on the ListView period.
  /// @param time DateTime
  /// @return Color.
  Color? _getSectionColor(DateTime time) {

    int colorIndex = 0;

    if (widget.sectionTime == TimeSeekSlider.section24Hours) {
      // use Second Color if the number of days elapsed since January 1, 1900 is an odd number.
      var diff = time.difference(DateTime(1900,1,1));
      if ((diff.inDays % 2) == 1) {
        colorIndex = 1;
      }
    } else if (widget.sectionTime == TimeSeekSlider.sectionMinute) {
      // use Second Color if the minute of time is odd number.
      if ((time.minute % 2) == 1) {
        colorIndex = 1;
      }
    } else if (widget.sectionTime == TimeSeekSlider.section10Minute) {
      // use Second Color if the minute of time is 1x,3x or 5x .
      if (((time.minute ~/ 10) % 2) == 1) {
        colorIndex = 1;
      }
    } else if (widget.sectionTime == TimeSeekSlider.section12Hours) {
      // use Second Color if the hour of time is 12 -23.
      if ((time.hour ~/ 12) == 1) {
        colorIndex = 1;
      }
    } else if (widget.sectionTime == TimeSeekSlider.section3Hours) {
      // use Second Color if the hour of time is 3~5 or 9~11.
      if (((time.hour ~/3) % 2) == 1) {
        colorIndex = 1;
      }
    } else if (widget.sectionTime == TimeSeekSlider.sectionHour) {
      // use Second Color if the hour of time is odd number.
      if ((time.hour % 2) == 1) {
        colorIndex = 1;
      }
    }

    // Check the time is in the fixed term.
    if (widget.fixedTerm && widget.from != null && widget.to != null) {
      if (time.isBefore(widget.from!)) {
        return Colors.grey[400];
      } else if (widget.to!.isBefore(time) || widget.to!.isAtSameMomentAs(time)) {
        return Colors.grey[400];
      }
    }

    if (widget.sectionColorPrimery == null || widget.sectionColorSecondary == null) {
      return colorIndex == 0 ? Colors.grey[300] : Colors.grey[400];
    }
    return colorIndex == 0 ? widget.sectionColorPrimery : widget.sectionColorSecondary;
  }

  @override
  Widget build(BuildContext context) {
    //print('[TimeSeekSlider.build] Enter');

    return LayoutBuilder(
      builder: (context, constraints) {
        //print('[TimeSeekSlider.LayoutBuilder] Enter');
        //print('    Current   : ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_currentTime)}');
        //print('    Period End: ~ ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_periodEnd)}');
        //print('    Scrl Limit: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_scrollLimitFrom)} ~ ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_scrollLimitTo)}');

        // Get latest size before build.
        _width = constraints.maxWidth;
        _height = constraints.maxHeight;
        _offset = widget.sectionWidth - constraints.maxWidth / 2;

        // num of sections in ListView.
        _numSections = _width ~/ widget.sectionWidth;
        if (_numSections < 10) {
          _numSections = 10;
        }
        //print('[TimeSeekSlider.LayoutBuilder] (w, h)=(${_width}, ${_height}) , offset=$_offset, numSections=$_numSections');

        // Show current time over center line
        var showCurrentTime = false;
        if (widget.showCurrentTime != null) {
          if (widget.showCurrentTime == ShowCurrentTime.showAlways) {
            showCurrentTime = true;
          } else if (widget.showCurrentTime == ShowCurrentTime.showDuringDragging && _isScrolling) {
            showCurrentTime = true;
          }
        }

        // Scroll ListView to specific position.
        if (_isScrolling == false) {
          //print('[build] Update Scroll Position (isScrolling = false)');
          // Update the term of ListView because out of scroll limit.
          if (_currentTime.isAfter(_scrollLimitTo)) {
            //print('    Over scroll limit.');
            // set period end to (current time + 10 sections).
            _periodEnd = _calcPeriod(_currentTime.add(Duration(seconds: widget.sectionTime * _numSections)));
            _scrollLimitFrom = _calcPeriod(_currentTime.subtract(Duration(seconds: widget.sectionTime * _numSections)));
            _scrollLimitTo = _calcPeriod(_periodEnd.subtract(Duration(seconds: widget.sectionTime * (_numSections ~/ 2) + 1)));
          }
          if (_currentTime.isBefore(_scrollLimitFrom)) {
            //print('    Under scroll limit.');
            // set period end to (current time + 10 sections).
            _periodEnd = _calcPeriod(_currentTime.add(Duration(seconds: widget.sectionTime * _numSections)));
            _scrollLimitFrom = _calcPeriod(_currentTime.subtract(Duration(seconds: widget.sectionTime * _numSections)));
            _scrollLimitTo = _calcPeriod(_periodEnd.subtract(Duration(seconds: widget.sectionTime * (_numSections ~/ 2) + 1)));
          }
          _scrollToPosition(_getSelectedPosition(_currentTime));
        } else {
          // don't scroll when scrolling manually by user.
          _isScrolling = false;
        }

        return GestureDetector(
          onTapUp: (detail) {
            // Move to tapped position when tapped
            _onTapSlider(detail.localPosition.dx);
          },
          child: Stack(
            children: [
              ListView.builder(
                key: _widgetKey,
                scrollDirection: Axis.horizontal,
                reverse: true,
                controller: _scrollController,
                itemBuilder: (context, index) {

                  // Calculate the term of this item.
                  final itemStart = _periodEnd.subtract(Duration(seconds: (index) * widget.sectionTime));
                  final itemEnd = _periodEnd.subtract(Duration(seconds: (index-1) * widget.sectionTime));

                  // Get the background color of this item.
                  var bgColor = _getSectionColor(itemStart);

                  // Get the DateTime string displayed on this item.
                  String periodEndText;
                  String periodStartText;
                  if (widget.sectionTime == TimeSeekSlider.section24Hours) {
                    // Display Date if section time is 24 hours.
                    var periodEndVal = itemEnd.month;
                    var periodStartVal = itemStart.day;
                    periodEndText = periodEndVal.toString();
                    periodStartText = '/$periodStartVal';

                  } else {
                    // Display Time (HH:mm).
                    var periodEndVal = itemEnd.hour;
                    var periodStartVal = itemStart.minute;
                    periodEndText = periodEndVal.toString().padLeft(2, "0");
                    periodStartText = ':${periodStartVal.toString().padLeft(2, "0")}';
                  }

                  // Get the events included in term of this item.
                  List<OverlayEvent> overlayEvents = [];
                  bool isEvent = (widget.events != null);
                  if (widget.fixedTerm && widget.from != null && widget.to != null) {
                    if (itemStart.isBefore(widget.from!) || itemStart.isAfter(widget.to!) || itemStart.isAtSameMomentAs(widget.to!) ) {
                      isEvent = false;
                    }
                  }
                  if (isEvent) {
                    for (var event in widget.events!) {
                      for(var period in event.events) {
                        var relatedPeriod = period.getRelatedPeriod(itemStart, itemEnd);
                        if (relatedPeriod != null) {
                          var x = relatedPeriod[0] * widget.sectionWidth;
                          var width = (relatedPeriod[1] - relatedPeriod[0]) * widget.sectionWidth;
                          if (width < 2.0) width = 2.0;
                          overlayEvents.add(OverlayEvent(x, 0, width, event.height, event.color));
                        }
                      }
                    }
                  }

                  return Container(
                    width: widget.sectionWidth.toDouble(),
                    color: bgColor,
                    // color: bgColor,
                    child: Stack(
                      children: [
                        // ':mm' or '/dd'
                        Align(
                          alignment: const Alignment(-1.0, -1.0),
                          child: Text(periodStartText,
                            style: TextStyle(color: widget.timeTextColor ?? Colors.black),
                          ),
                        ),
                        // 'HH' or 'M'
                        Align(
                          alignment: const Alignment(1.0, -1.0),
                          child: Text(periodEndText,
                            style: TextStyle(color: widget.timeTextColor ?? Colors.black),
                          ),
                        ),
                        // Events
                        for(var oe in overlayEvents)
                          Positioned(
                            left: oe.left,
                            bottom: 0,
                            width: oe.width.toDouble(),
                            height: _height * oe.height.toDouble() / 100,
                            child: Container(color: oe.color,),
                          ),
                      ],
                    ),
                  );
                },
                itemCount: null, // Set null for infinite scroll
              ),
              // Center Line
              Align(
                alignment: const Alignment(0.0, -1.0),
                child: Container(width: 2, color: widget.centerLineColor ?? Colors.black,),
              ),
              Align(
                alignment: const Alignment(0.0, -1.0),
                child: CustomPaint(
                  size: Size(_height * 0.2, _height * 0.1),
                  painter: TrianglePaint(fillColor: widget.centerLineColor),
                )
              ),
              if (showCurrentTime)
                Align(
                  alignment: const Alignment(0.0, -1.0),
                  child: Padding(
                    padding: EdgeInsets.only(top: _height * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: widget.currentTimeTextBackgroundColor ?? Colors.transparent),
                      child: Text(DateFormat('HH:mm:ss').format(_draggingTime),
                        style: TextStyle(color: widget.currentTimeTextColor ?? Colors.black),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      });
  }
}

/// Type of show current time.
enum ShowCurrentTime {
  /// don't show current time
  dontShow,
  /// show current time always
  showAlways,
  /// show current time during dragging
  showDuringDragging,
}

/// Event information class.
///
/// Prepare each layer.
class TimeEvent {
  /// Height of event rectangle.
  ///
  /// This is rate (0-100 %).
  double height;

  /// Color of event rectangle.
  Color color;

  /// List of event terms.
  List<TimePeriod> events;

  TimeEvent(this.height, this.color, this.events);
}

/// Period of event.
class TimePeriod {
  /// Start DateTime of event.
  DateTime from;
  /// End DateTime of event.
  DateTime to;

  TimePeriod(this.from, this.to);

  /// Get the range of events included in the specified period.
  /// Expressed as a ratio between 0.0 and 1.0.
  /// @return  [0]: start , [1]: end
  List<double>? getRelatedPeriod(DateTime start, DateTime end) {

    if (start.millisecondsSinceEpoch <= from.millisecondsSinceEpoch) {
      var size = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      if (to.millisecondsSinceEpoch <= end.millisecondsSinceEpoch) {
        // start ------- end
        //    from -- to
        var widthFrom = from.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
        var widthTo = to.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
        var itemStart = widthFrom / size;
        var itemEnd = widthTo / size;
        return [itemStart, itemEnd];

      } else if (from.millisecondsSinceEpoch <= end.millisecondsSinceEpoch) {
        // start ------- end
        //      from ---------
        var width = from.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
        var itemStart = width / size;
        return [itemStart, 1.0];
      }

    } else if (start.millisecondsSinceEpoch <= to.millisecondsSinceEpoch &&
        to.millisecondsSinceEpoch <= end.millisecondsSinceEpoch) {
      //   start ------ end
      // ---------- to
      var size = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      var width = to.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      var itemEnd = width / size;
      return [0.0, itemEnd];

    } else if (from.millisecondsSinceEpoch <= start.millisecondsSinceEpoch &&
        end.millisecondsSinceEpoch <= to.millisecondsSinceEpoch) {
      //     start -- end
      // from ------------ to
      return [0.0, 1.0];
    }

    return null;
  }
}

/// Event information for drawing
class OverlayEvent {
  /// Left position of rectangle.
  double left;
  /// Bottom position of rectangle.
  double bottom;
  /// Width of rectangle.
  double width;
  /// Height of rectangle.
  double height;
  /// Color of rectangle
  Color color;

  OverlayEvent(this.left, this.bottom, this.width, this.height, this.color);
}


/// Draw upside down triangle.
class TrianglePaint extends CustomPainter {
  Color? fillColor;

  TrianglePaint({this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0,)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0,);

    final paint = Paint()
      ..color = fillColor ?? Colors.black
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
