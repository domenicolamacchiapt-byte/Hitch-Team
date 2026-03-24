import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tzData.initializeTimeZones();
  print(tz.TZDateTime.now(tz.UTC));
}
