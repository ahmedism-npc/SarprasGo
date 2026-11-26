import 'package:intl/intl.dart';

const _wibOffset = Duration(hours: 7);

DateTime get wibNow => DateTime.now().toUtc().add(_wibOffset);

/// Build a WIB wall-clock time and convert it to the UTC instant sent to Supabase.
DateTime wibWallTimeToUtc(DateTime wallTime) =>
    DateTime.utc(wallTime.year, wallTime.month, wallTime.day, wallTime.hour, wallTime.minute)
        .subtract(_wibOffset);

String formatWib(DateTime instant, String pattern) => DateFormat(pattern, 'id_ID')
    .format(instant.toUtc().add(_wibOffset));
