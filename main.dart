import 'dart:io';

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

  List<String> get borrowedResources =>
      List.unmodifiable(_borrowedResources);

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
    stdout.write(message);
    String? input = stdin.readLineSync();

    if (input == null || input.trim().isEmpty) {
      print('Invalid input! This field cannot be empty.');
      return null;
    }

    return input.trim();
  }

  int? readMenuChoice() {
    stdout.write('Enter your choice: ');

    String? input = stdin.readLineSync();

    try {
      int choice = int.parse(input ?? '');

      if (choice < 1 || choice > 8) {
        print('Invalid choice! Please select from 1 to 8.');
        return null;
      }

      return choice;
    } catch (e) {
      print('Invalid input! Please enter a valid number.');
      return null;
    }
  }

  // ADD LEARNING RESOURCE

  void addResource() {
    print('\n========== ADD LEARNING RESOURCE ==========');

    String? title = readRequired('Enter resource title: ');
    if (title == null) return;

    String? category = readRequired('Enter resource category: ');
    if (category == null) return;

    String id =
        'R${_resourceCounter.toString().padLeft(3, '0')}';

    LearningResource resource =
        LearningResource(id, title, category);

    _resources.add(resource);
    _records[id] = resource;

    _resourceCounter++;

    print('\nResource successfully added!');
    print('Generated Resource ID: $id');
  }

  // REGISTER PARTICIPANT

  void registerParticipant() {
    print('\n========== REGISTER PARTICIPANT ==========');

    String? name = readRequired('Enter participant name: ');
    if (name == null) return;

    String? email = readRequired('Enter participant email: ');
    if (email == null) return;

    if (!email.contains('@') || !email.contains('.')) {
      print('Invalid email address!');
      return;
    }

    String id =
        'P${_participantCounter.toString().padLeft(3, '0')}';

    Participant participant = Participant(id, name, email);

    _participants.add(participant);
    _records[id] = participant;

    _participantCounter++;

    print('\nParticipant successfully registered!');
    print('Generated Participant ID: $id');
  }

  // BORROW LEARNING RESOURCE

  void borrowResource() {
    print('\n========== BORROW LEARNING RESOURCE ==========');

    if (_participants.isEmpty || _resources.isEmpty) {
      print('You need at least one participant and one resource.');
      return;
    }

    displayResources();

    String? participantId =
        readRequired('\nEnter Participant ID: ');
    if (participantId == null) return;

    String? resourceId =
        readRequired('Enter Resource ID: ');
    if (resourceId == null) return;

    // Retrieve records through Map
    CenterRecord? participantRecord = _records[participantId];
    CenterRecord? resourceRecord = _records[resourceId];

    if (participantRecord is! Participant) {
      print('Participant not found!');
      return;
    }

    if (resourceRecord is! LearningResource) {
      print('Learning resource not found!');
      return;
    }

    Participant participant = participantRecord;
    LearningResource resource = resourceRecord;

    if (!resource.isAvailable) {
      print('Sorry! This resource is already borrowed.');
      return;
    }

    // Process transaction
    if (resource.borrowResource()) {
      participant.addBorrowedResource(resource.id);

      print('\nBorrowing successful!');
      print('${participant.name} borrowed "${resource.name}".');
    }
  }

  // RETURN LEARNING RESOURCE

  void returnResource() {
    print('\n========== RETURN LEARNING RESOURCE ==========');

    String? participantId =
        readRequired('Enter Participant ID: ');
    if (participantId == null) return;

    String? resourceId =
        readRequired('Enter Resource ID: ');
    if (resourceId == null) return;

    CenterRecord? participantRecord = _records[participantId];
    CenterRecord? resourceRecord = _records[resourceId];

    if (participantRecord is! Participant) {
      print('Participant not found!');
      return;
    }

    if (resourceRecord is! LearningResource) {
      print('Resource not found!');
      return;
    }

    Participant participant = participantRecord;
    LearningResource resource = resourceRecord;

    if (!participant.borrowedResources.contains(resource.id)) {
      print('This participant did not borrow that resource.');
      return;
    }

    if (resource.returnResource()) {
      participant.removeBorrowedResource(resource.id);

      print('\nReturn successful!');
      print('${resource.name} has been returned.');
    }
  }

  // DISPLAY RESOURCES

  void displayResources() {
    print('\n========== LEARNING RESOURCES ==========');

    if (_resources.isEmpty) {
      print('No learning resources registered.');
      return;
    }

    for (LearningResource resource in _resources) {
      print('''
--------------------------------
ID: ${resource.id}
Title: ${resource.name}
Category: ${resource.category}
Status: ${resource.isAvailable ? "Available" : "Borrowed"}
''');
    }
  }

  // DISPLAY PARTICIPANTS
  void displayParticipants() {
    print('\n========== PARTICIPANTS ==========');

    if (_participants.isEmpty) {
      print('No participants registered.');
      return;
    }

    for (Participant participant in _participants) {
      print(participant.getRecordDetails());
    }
  }

  // DISPLAY ALL RECORDS

  void displayAllRecords() {
    print('\n========== ALL CENTER RECORDS ==========');

    if (_records.isEmpty) {
      print('No records available.');
      return;
    }

    // Polymorphism
    for (CenterRecord record in _records.values) {
      print('--------------------------------');
      print(record.getRecordDetails());
    }
  }

  // SEARCH RECORD
  void searchRecord() {
    print('\n========== SEARCH RECORD ==========');

    String? id = readRequired('Enter Record ID: ');
    if (id == null) return;

    CenterRecord? record = _records[id];

    if (record != null) {
      print('\nRecord found!');
      print(record.getRecordDetails());
    } else {
      print('No record found with ID: $id');
    }
  }

  // SYSTEM SUMMARY

  void displaySummary() {
    print('\n========== SYSTEM SUMMARY ==========');

    int totalResources = _resources.length;
    int totalParticipants = _participants.length;

    int availableResources = _resources
        .where((resource) => resource.isAvailable)
        .length;

    int borrowedResources = totalResources - availableResources;

    // Calculation using operators
    double availabilityRate = totalResources == 0
        ? 0.0
        : (availableResources / totalResources) * 100;

    print('Total Learning Resources: $totalResources');
    print('Total Participants: $totalParticipants');
    print('Available Resources: $availableResources');
    print('Borrowed Resources: $borrowedResources');

    print(
      'Resource Availability Rate: ${availabilityRate.toStringAsFixed(2)}%',
    );
  }

  // MAIN MENU

  void displayMenu() {
    print('\n============================================');
    print(' COMMUNITY LEARNING CENTER MANAGEMENT SYSTEM');
    print('============================================');
    print('[1] Add Learning Resource');
    print('[2] Register Participant');
    print('[3] Borrow Learning Resource');
    print('[4] Return Learning Resource');
    print('[5] View All Records');
    print('[6] Search Record');
    print('[7] View System Summary');
    print('[8] Exit');
    print('============================================');
  }

  // RUN APPLICATION
Future<void> run() async {
  bool isRunning = true;

  print('\nWelcome to the Community Learning Center!');

  await Future.delayed(Duration(seconds: 2));

  while (isRunning) {
    await clearScreen();

    displayMenu();

    int? choice = readMenuChoice();

    if (choice == null) {
      print('\nPress ENTER to try again...');
      stdin.readLineSync();
      continue;
    }

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
          print('\nThank you for using the system!');
          print('Application terminated successfully.');
          break;
      }
    } catch (e) {
      print('\nAn unexpected error occurred: $e');
    }

    if (isRunning) {
      print('\nPress ENTER to return to the main menu...');
      stdin.readLineSync();
    }
  }
}
}
// MAIN FUNCTION
Future<void> main() async {
  LearningCenterSystem system = LearningCenterSystem();

  await system.run();
}