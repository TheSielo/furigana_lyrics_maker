import 'package:shared_preferences/shared_preferences.dart';

enum BoolPref {
  isFirstAccess, neverUnlockedTimestamps
}

enum StringPref {
  lastSongId,
  songsList,
}

class PreferencesHelper {
  static Future<bool> getBool(BoolPref key, bool defValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool value = prefs.getBool(key.toString().toLowerCase()) ?? defValue;
    return value;
  }

  static Future setBool(BoolPref key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key.toString().toLowerCase(), value);
  }

  static Future<String> getString(StringPref key,
      {String defaultValue = ''}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String value =
        prefs.getString(key.toString().toLowerCase()) ?? defaultValue;
    return value;
  }

  static Future setString(StringPref key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.toString().toLowerCase(), value);
  }

  static Future deletePref(Enum key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key.toString().toLowerCase());
  }

  static Future<String> readFile(String filename) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String value = prefs.getString(filename) ?? '{}';
    return value;
  }

  static Future writeFile(String filename, String content) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(filename, content);
  }

  static Future deleteFile(String filename) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(filename);
  }
}
