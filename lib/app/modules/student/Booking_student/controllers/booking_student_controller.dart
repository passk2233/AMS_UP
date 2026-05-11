import 'package:get/get.dart';

class BookingStudentController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var currentWeek = <DateTime>[].obs;
  var selectedSlots = <String, String>{}.obs;
  var selectedBuilding = 'All Rooms'.obs;

  final rooms = <Map<String, dynamic>>[
    {
      'name': 'A301',
      'capacity': '90',
      'facilities': 'Projector',
      'building': 'ตึก A',
      'slots': [
        {'time': '9:00 AM', 'status': 'available'},
        {'time': '10:00 AM', 'status': 'booked'},
        {'time': '11:00 AM', 'status': 'available'},
        {'time': '12:00 PM', 'status': 'available'},
        {'time': '13:00 PM', 'status': 'available'},
      ],
    },
    {
      'name': 'Conference',
      'capacity': '56',
      'facilities': 'Projector & Whiteboard',
      'building': 'ตึก CEIT',
      'slots': [
        {'time': '9:00 AM', 'status': 'available'},
        {'time': '10:00 AM', 'status': 'available'},
        {'time': '11:00 AM', 'status': 'available'},
        {'time': '12:00 PM', 'status': 'available'},
        {'time': '13:00 PM', 'status': 'available'},
      ],
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    generateWeek(DateTime.now());
  }

  void generateWeek(DateTime startDay) {
    List<DateTime> days = [];
    for (int i = -3; i <= 3; i++) {
      days.add(startDay.add(Duration(days: i)));
    }
    currentWeek.value = days;
  }

  void selectDate(DateTime date) => selectedDate.value = date;

  void selectSlot(String roomName, String time) => selectedSlots[roomName] = time;

  void changeBuilding(String label) => selectedBuilding.value = label;

  List<Map<String, dynamic>> get filteredRooms {
    if (selectedBuilding.value == 'All Rooms') return rooms;
    return rooms.where((r) => r['building'] == selectedBuilding.value).toList();
  }

  void bookSlot(String roomName, String time) {
    int roomIdx = rooms.indexWhere((r) => r['name'] == roomName);
    if (roomIdx != -1) {
      List<Map<String, dynamic>> slots = List<Map<String, dynamic>>.from(rooms[roomIdx]['slots']);
      int slotIdx = slots.indexWhere((s) => s['time'] == time);
      if (slotIdx != -1) {
        slots[slotIdx]['status'] = 'booked';
        rooms[roomIdx]['slots'] = slots;
        rooms.refresh(); // บังคับ UI อัปเดต
        selectedSlots.remove(roomName);
      }
    }
  }
}