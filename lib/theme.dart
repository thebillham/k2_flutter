import 'package:flutter/material.dart';

final ThemeData CompanyThemeData = new ThemeData(
  brightness: Brightness.light,
  primaryColor: CompanyColors.colorPrimaryLight,
  primaryColorBrightness: Brightness.dark,
  accentColor: CompanyColors.accentRippled,
  accentColorBrightness: Brightness.dark,
);

class CompanyColors {
  static const Color colorPrimaryLight = Color(0xFF3D9976);
  static const Color colorPrimaryDark = Color(0xFF006D44);
  static const Color accent = Color(0xFFFF2D00);
  static const Color accentPressed = Color(0xFFD32500);
  static const Color accentRippled = Color(0xFFFFA28E);

  // icon colours
  static const Color iconYellow = Color(0xFFFFE070);
  static const Color iconPink = Color(0xFFFF0065);
  static const Color iconBrown = Color(0xFF995446);
  static const Color iconDGreen = Color(0xFF87CC14);
  static const Color iconLGreen = Color(0xFF74FF40);

  // score colours
  static const Color score0 = Color(0xFFBDE1EC);
  static const Color score0no = Color(0xFFF7FBFD);
  static const Color score1 = Color(0xFFB2E6A1);
  static const Color score1no = Color(0xFFF5FCF3);
  static const Color score2 = Color(0xFFFFD930);
  static const Color score2no = Color(0xFFFFFAE5);
  static const Color score3 = Color(0xFFE33714);
  static const Color score3no = Color(0xFFFBE6E2);

  // result colours
  static const Color resultHigh = Color(0xFFE33714);
  static const Color resultMid = Color(0xFFFFD930);
  static const Color resultLow = Color(0xFFB2E6A1);

  // icon colours
  static const Color checkNo = Color(0xFFE33714);
  static const Color checkMaybe = Color(0xFFFFD930);
  static const Color checkYes = Color(0xFFB2E6A1);

  // acm key colours
  static const Color acmPositive = Color(0xFFE33714);
  static const Color strongPresume = Color(0xFFFFA930);
  static const Color weakPresume = Color(0xFFFFD930);
  static const Color acmNegative = Color(0xFFB2E6A1);

  // icons
  static Icon asbestosIcon = new Icon(Icons.whatshot, color: iconYellow);
  static Icon methIcon = new Icon(Icons.lightbulb_outline, color: iconPink);
  static Icon noiseIcon = new Icon(Icons.hearing, color: iconBrown);
  static Icon bioIcon = new Icon(Icons.local_florist, color: iconDGreen);
//  static Icon stackIcon = new Icon(
//      Icons.hot_tub, color: iconYellow
//  );
  static Icon stackIcon = new Icon(Icons.filter_drama, color: iconLGreen);

  static Icon generalIcon = new Icon(Icons.assignment);
}
