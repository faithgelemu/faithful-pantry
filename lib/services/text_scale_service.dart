
import 'package:shared_preferences/shared_preferences.dart';

class TextScaleService {
  static const String _textScaleKey = 'text_scale';

  static const double defaultScale = 1.0;
  static const double minScale = 0.8;
  static const double maxScale = 1.5;

  Future<double> loadTextScale() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getDouble(_textScaleKey) ?? defaultScale;
  }

  Future<void> saveTextScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_textScaleKey, scale);
  }
}
