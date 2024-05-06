import 'package:flutter_test/flutter_test.dart';

import 'package:time_seek_slider/time_seek_slider.dart';

void main() {
  test('Test getRelatedPeriod()', () {

    // Event
    var timePeriods = TimePeriod(
          DateTime(2024,4,28,13,00,0),
          DateTime(2024,4,28,13,30,0));

    // event :               start -- end
    // period: from --- to
    expect(timePeriods.getRelatedPeriod(
        DateTime(2024,4,28,12,0), DateTime(2024,4,28,12,10)),
        null
    );

    // event :     start -- end
    // period: from ------------ to
    expect(timePeriods.getRelatedPeriod(
        DateTime(2024,4,28,12,0), DateTime(2024,4,28,14,00)),
        [0.5, 0.75]
    );

    // event :   start ------ end
    // period: ---------- to
    expect(timePeriods.getRelatedPeriod(
        DateTime(2024,4,28,13,0), DateTime(2024,4,28,14,00)),
        [0.0, 0.5]
    );

    // event:  start ------- end
    // period:      from -- to
    expect(timePeriods.getRelatedPeriod(
        DateTime(2024,4,28,13,10), DateTime(2024,4,28,13,20)),
      [0.0, 1.0]
    );

    // event:  start ------- end
    //period:         from ---------
    expect(timePeriods.getRelatedPeriod(
        DateTime(2024,4,28,12,30), DateTime(2024,4,28,13,30)),
        [0.5, 1.0]
    );
  });
}
