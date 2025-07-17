import 'package:flutter/foundation.dart';

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://sum25-go-flutter-course.onrender.com',
);

const wellnessBase    = '$apiBase/api/wellness';
const activityBase    = '$apiBase/api/activities';
const nutritionBase   = '$apiBase/api/nutrition';
const usersBase       = '$apiBase/api/users';
