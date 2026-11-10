import 'dart:io';
import 'dart:math';

// UI THEME

class UI {
  // ANSI color
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String blue = '\x1B[38;5;39m';
  static const String pink = '\x1B[38;5;213m';
  static const String yellow = '\x1B[38;5;226m';
  static const String white = '\x1B[97m';

  // Terminal size
  static int get width {
    try {
      return stdout.hasTerminal ? stdout.terminalColumns : 80;
    } catch (_) {
      return 80;
    }
  }

  static int get height {
    try {
      return stdout.hasTerminal ? stdout.terminalLines : 24;
    } catch (_) {
      return 24;
    }
  }

  static String _strip(String s) =>
      s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

  static String _margin(int contentWidth) =>
      ' ' * max(0, (width - contentWidth) ~/ 2);

  // Print line centered
  static void center(String text, {String color = ''}) {
    print('${_margin(_strip(text).length)}$color$text$reset');
  }

  static void block(List<String> lines, {String color = white}) {
    final int w =
        lines.fold(0, (int a, String l) => max(a, _strip(l).length));
    final String m = _margin(w);
    for (final String line in lines) {
      print('$m$color$line$reset');
    }
  }

  static String _colorizeLine(String line) {
    final int i = line.indexOf(':');
    if (i == -1) return '$white$line$reset';
    return '$blue${line.substring(0, i + 1)}$reset '
        '$yellow${line.substring(i + 1).trim()}$reset';
  }

  static void details(String text) {
    block(text.trim().split('\n').map(_colorizeLine).toList());
  }

  static void divider({int length = 44, String ch = '-'}) {
    center(ch * length, color: pink);
  }

  static void heading(String title) {
    final String line = '=' * (title.length + 8);
    print('');
    center(line, color: blue);
    center(title, color: '$bold$pink');
    center(line, color: blue);
    print('');
  }

  static void success(String msg) => center(msg, color: yellow);
  static void error(String msg) => center(msg, color: '$bold$pink');
  static void info(String msg) => center(msg, color: white);

  static String? ask(String label) {
    final String m = _margin(label.length + 24);
    stdout.write('$m$pink$label$reset$yellow');
    final String? input = stdin.readLineSync();
    stdout.write(reset);
    return input;
  }

  static void pause(String message) {
    print('');
    center(message, color: yellow);
    stdin.readLineSync();
  }
}

// Clear console screen function so that the user interface is cleaner
Future<void> clearScreen() async {
  if (Platform.isWindows) {
    final process = await Process.start(
      'cmd',
      ['/c', 'cls'],
      mode: ProcessStartMode.inheritStdio,
    );
    await process.exitCode;
  } else {
    print('\x1B[2J\x1B[H');
  }
}

// MIXIN: Reusable timestamp behavior
mixin TimestampMixin {
  final DateTime createdAt = DateTime.now();

  String get dateCreated {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

// ABSTRACT PARENT CLASS

abstract class CenterRecord {
  final String _id;
  String _name;

  CenterRecord(this._id, this._name);

  // Encapsulation using getters
  String get id => _id;
  String get name => _name;

  // Controlled access through setter
  set name(String newName) {
    if (newName.trim().isNotEmpty) {
      _name = newName.trim();
    }
  }

  // Abstract method implemented by subclasses
  String getRecordDetails();
}

// SUBCLASS 1: LEARNING RESOURCE

class LearningResource extends CenterRecord with TimestampMixin {
  String _category;
  bool _isAvailable;

  LearningResource(
    String id,
    String title,
    this._category,
  )   : _isAvailable = true,
        super(id, title);

  String get category => _category;
  bool get isAvailable => _isAvailable;

  // Borrow resource
  bool borrowResource() {
    if (_isAvailable) {
      _isAvailable = false;
      return true;
    }
    return false;
  }

  // Return resource
  bool returnResource() {
    if (!_isAvailable) {
      _isAvailable = true;
      return true;
    }
    return false;
  }

  // Polymorphism: implementation of abstract method
  @override
  String getRecordDetails() {
    return '''
Resource ID: $id
Title: $name
Category: $_category
Status: ${_isAvailable ? "Available" : "Borrowed"}
Date Added: $dateCreated
''';
  }
}

// SUBCLASS 2: PARTICIPANT

class Participant extends CenterRecord with TimestampMixin {
  String _email;
  final List<String> _borrowedResources = [];

  Participant(
    String id,
    String participantName,
    this._email,
  ) : super(id, participantName);

  String get email => _email;

  List<String> get borrowedResources => List.unmodifiable(_borrowedResources);

  // Register borrowed resource
  void addBorrowedResource(String resourceId) {
    if (!_borrowedResources.contains(resourceId)) {
      _borrowedResources.add(resourceId);
    }
  }

  // Remove returned resource
  bool removeBorrowedResource(String resourceId) {
    return _borrowedResources.remove(resourceId);
  }

  // Polymorphism: implementation of abstract method
  @override
  String getRecordDetails() {
    return '''
Participant ID: $id
Name: $name
Email: $_email
Borrowed Resources: ${_borrowedResources.length}
Date Registered: $dateCreated
''';
  }
}

// MAIN SYSTEM CLASS

class LearningCenterSystem {
  // Lists for storing records
  final List<LearningResource> _resources = [];
  final List<Participant> _participants = [];

  // Map for retrieving records using their IDs
  final Map<String, CenterRecord> _records = {};

  int _resourceCounter = 1;
  int _participantCounter = 1;

  // INPUT VALIDATION FUNCTIONS

  String? readRequired(String message) {
    String? input = UI.ask(message);

    if (input == null || input.trim().isEmpty) {
      UI.error('Invalid input! This field cannot be empty.');
      return null;
    }

    return input.trim();
  }

  int? readMenuChoice() {
    String? input = UI.ask('Enter your choice: ');

    try {
      int choice = int.parse(input ?? '');

      if (choice < 1 || choice > 8) {
        UI.error('Invalid choice! Please select from 1 to 8.');
        return null;
      }

      return choice;
    } catch (e) {
      UI.error('Invalid input! Please enter a valid number.');
      return null;
    }
  }

  // ADD LEARNING RESOURCE

  void addResource() {
    UI.heading('ADD LEARNING RESOURCE');

    String? title = readRequired('Enter resource title: ');
    if (title == null) return;

    String? category = readRequired('Enter resource category: ');
    if (category == null) return;

    String id = 'R${_resourceCounter.toString().padLeft(3, '0')}';

    LearningResource resource = LearningResource(id, title, category);

    _resources.add(resource);
    _records[id] = resource;

    _resourceCounter++;

    print('');
    UI.success('Resource successfully added!');
    UI.success('Generated Resource ID: $id');
  }

  // REGISTER PARTICIPANT

  void registerParticipant() {
    UI.heading('REGISTER PARTICIPANT');

    String? name = readRequired('Enter participant name: ');
    if (name == null) return;

    String? email = readRequired('Enter participant email: ');
    if (email == null) return;

    if (!email.contains('@') || !email.contains('.')) {
      UI.error('Invalid email address!');
      return;
    }

    String id = 'P${_participantCounter.toString().padLeft(3, '0')}';

    Participant participant = Participant(id, name, email);

    _participants.add(participant);
    _records[id] = participant;

    _participantCounter++;

    print('');
    UI.success('Participant successfully registered!');
    UI.success('Generated Participant ID: $id');
  }

  // BORROW LEARNING RESOURCE

  void borrowResource() {
    UI.heading('BORROW LEARNING RESOURCE');

    if (_participants.isEmpty || _resources.isEmpty) {
      UI.error('You need at least one participant and one resource.');
      return;
    }

    displayResources(showHeading: false);

    print('');
    String? participantId = readRequired('Enter Participant ID: ');
    if (participantId == null) return;

    String? resourceId = readRequired('Enter Resource ID: ');
    if (resourceId == null) return;

    // Retrieve records through Map
    CenterRecord? participantRecord = _records[participantId];
    CenterRecord? resourceRecord = _records[resourceId];

    if (participantRecord is! Participant) {
      UI.error('Participant not found!');
      return;
    }

    if (resourceRecord is! LearningResource) {
      UI.error('Learning resource not found!');
      return;
    }

    Participant participant = participantRecord;
    LearningResource resource = resourceRecord;

    if (!resource.isAvailable) {
      UI.error('Sorry! This resource is already borrowed.');
      return;
    }

    // Process transaction
    if (resource.borrowResource()) {
      participant.addBorrowedResource(resource.id);

      print('');
      UI.success('Borrowing successful!');
      UI.success('${participant.name} borrowed "${resource.name}".');
    }
  }

  // RETURN LEARNING RESOURCE

  void returnResource() {
    UI.heading('RETURN LEARNING RESOURCE');

    String? participantId = readRequired('Enter Participant ID: ');
    if (participantId == null) return;

    String? resourceId = readRequired('Enter Resource ID: ');
    if (resourceId == null) return;

    CenterRecord? participantRecord = _records[participantId];
    CenterRecord? resourceRecord = _records[resourceId];

    if (participantRecord is! Participant) {
      UI.error('Participant not found!');
      return;
    }

    if (resourceRecord is! LearningResource) {
      UI.error('Resource not found!');
      return;
    }

    Participant participant = participantRecord;
    LearningResource resource = resourceRecord;

    if (!participant.borrowedResources.contains(resource.id)) {
      UI.error('This participant did not borrow that resource.');
      return;
    }

    if (resource.returnResource()) {
      participant.removeBorrowedResource(resource.id);

      print('');
      UI.success('Return successful!');
      UI.success('${resource.name} has been returned.');
    }
  }

  // DISPLAY RESOURCES

  void displayResources({bool showHeading = true}) {
    if (showHeading) UI.heading('LEARNING RESOURCES');

    if (_resources.isEmpty) {
      UI.error('No learning resources registered.');
      return;
    }

    for (LearningResource resource in _resources) {
      UI.divider();
      UI.details('''
ID: ${resource.id}
Title: ${resource.name}
Category: ${resource.category}
Status: ${resource.isAvailable ? "Available" : "Borrowed"}
''');
    }
  }

  // DISPLAY PARTICIPANTS
  void displayParticipants() {
    UI.heading('PARTICIPANTS');

    if (_participants.isEmpty) {
      UI.error('No participants registered.');
      return;
    }

    for (Participant participant in _participants) {
      UI.divider();
      UI.details(participant.getRecordDetails());
    }
  }

  // DISPLAY ALL RECORDS

  void displayAllRecords() {
    UI.heading('ALL CENTER RECORDS');

    if (_records.isEmpty) {
      UI.error('No records available.');
      return;
    }

    // Polymorphism
    for (CenterRecord record in _records.values) {
      UI.divider();
      UI.details(record.getRecordDetails());
    }
  }

  // SEARCH RECORD
  void searchRecord() {
    UI.heading('SEARCH RECORD');

    String? id = readRequired('Enter Record ID: ');
    if (id == null) return;

    CenterRecord? record = _records[id];

    print('');
    if (record != null) {
      UI.success('Record found!');
      UI.divider();
      UI.details(record.getRecordDetails());
    } else {
      UI.error('No record found with ID: $id');
    }
  }

  // SYSTEM SUMMARY

  void displaySummary() {
    UI.heading('SYSTEM SUMMARY');

    int totalResources = _resources.length;
    int totalParticipants = _participants.length;

    int availableResources =
        _resources.where((resource) => resource.isAvailable).length;

    int borrowedResources = totalResources - availableResources;

    // Calculation using operators
    double availabilityRate = totalResources == 0
        ? 0.0
        : (availableResources / totalResources) * 100;

    UI.details('''
Total Learning Resources: $totalResources
Total Participants: $totalParticipants
Available Resources: $availableResources
Borrowed Resources: $borrowedResources
Resource Availability Rate: ${availabilityRate.toStringAsFixed(2)}%
''');
  }

  // MAIN MENU

  void displayMenu() {
    // Vertical centering (menu is about 17 lines tall)
    int topSpace = max(0, (UI.height - 17) ~/ 2);
    print('\n' * topSpace);

    const String bar = '============================================';
    UI.center(bar, color: UI.blue);
    UI.center('COMMUNITY LEARNING CENTER', color: '${UI.bold}${UI.pink}');
    UI.center('MANAGEMENT SYSTEM', color: '${UI.bold}${UI.pink}');
    UI.center(bar, color: UI.blue);
    print('');

    final List<String> items = [
      'Add Learning Resource',
      'Register Participant',
      'Borrow Learning Resource',
      'Return Learning Resource',
      'View All Records',
      'Search Record',
      'View System Summary',
      'Exit',
    ];

    UI.block([
      for (int i = 0; i < items.length; i++)
        '${UI.pink}[${i + 1}]${UI.reset} ${UI.yellow}${items[i]}${UI.reset}',
    ]);

    print('');
    UI.center(bar, color: UI.blue);
    print('');
  }

  // RUN APPLICATION
  Future<void> run() async {
    bool isRunning = true;

    await clearScreen();
    print('\n' * max(0, (UI.height ~/ 2) - 2));
    UI.center('Welcome to the', color: UI.yellow);
    UI.center('COMMUNITY LEARNING CENTER!', color: '${UI.bold}${UI.pink}');

    await Future.delayed(Duration(seconds: 2));

    while (isRunning) {
      await clearScreen();

      displayMenu();

      int? choice = readMenuChoice();

      if (choice == null) {
        UI.pause('Press ENTER to try again...');
        continue;
      }

      // Clear again so each chosen option appears as its own centered page
      await clearScreen();

      try {
        switch (choice) {
          case 1:
            addResource();
            break;

          case 2:
            registerParticipant();
            break;

          case 3:
            borrowResource();
            break;

          case 4:
            returnResource();
            break;

          case 5:
            displayAllRecords();
            break;

          case 6:
            searchRecord();
            break;

          case 7:
            displaySummary();
            break;

          case 8:
            isRunning = false;
            print('');
            UI.success('Thank you for using the system!');
            UI.info('Application terminated successfully.');
            break;
        }
      } catch (e) {
        UI.error('An unexpected error occurred: $e');
      }

      if (isRunning) {
        UI.pause('Press ENTER to return to the main menu...');
      }
    }
  }
}

// MAIN FUNCTION
Future<void> main() async {
  LearningCenterSystem system = LearningCenterSystem();

  await system.run();
}