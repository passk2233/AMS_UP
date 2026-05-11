import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ScheduleStudentController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var currentWeek = <DateTime>[].obs;

  final allSchedules = <Map<String, dynamic>>[
    {
      'date': DateTime(2026, 1, 27), // ปี, เดือน, วัน
      'title': 'Database 2',
      'subtitle': 'Using Sub-queries to Solve Queries',
      'time': '9:00 AM - 11:00 AM',
      'instructor': 'ຮສ ທາ ບຸນທັນ',
      'location': 'Conference',
      'color': Colors.purple,
    },
    {
      'date': DateTime(2026, 1, 27),
      'title': 'Web Programming',
      'subtitle': 'PHP + MySQL',
      'time': '13:00 PM - 15:00 PM',
      'instructor': 'ສຮ ແສງລັດສະໝີ จັນทະມີນາວົງ',
      'location': 'A212',
      'color': Colors.blue,
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _generateWeek(DateTime.now());
  }

  void _generateWeek(DateTime date) {
    int daysToSubtract = date.weekday % 7;
    DateTime firstDay = date.subtract(Duration(days: daysToSubtract));
    currentWeek.assignAll(List.generate(7, (i) => firstDay.add(Duration(days: i))));
  }

  void changeWeek(int days) {
    _generateWeek(currentWeek.first.add(Duration(days: days)));
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  List<Map<String, dynamic>> get filteredSchedules {
    // return allSchedules.where((s) {
    //   DateTime d = s['date'];
    //   return d.year == selectedDate.value.year &&
    //          d.month == selectedDate.value.month &&
    //          d.day == selectedDate.value.day;
    // }).toList();
    return allSchedules;
  }

  String get currentMonthYear => DateFormat('MMMM yyyy').format(selectedDate.value);
}