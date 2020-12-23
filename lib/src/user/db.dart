// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// class Db {
//   Database db;

//   Db.initializeData();

//   Db.getStudent();

//   Db.insertStudents(data);

//   Db.insertUser(user);

//   Db.getUser();

//   void initializeData() async {
//     var databasesPath = await getDatabasesPath();
//     String path = join(databasesPath, 'student_database.db');
//     db = await openDatabase(path, version: 1,
//         onCreate: (Database db, int version) async {
//       await db
//           .execute('CREATE TABLE user (id INTEGER PRIMARY KEY, user TEXT,) ');

//       await db.execute(
//           'CREATE TABLE students (id INTEGER PRIMARY KEY, name TEXT,  phone TEXT,  stdclass TEXT, week TEXT, ) ');

//       await db.execute(
//           'CREATE TABLE payments (id INTEGER PRIMARY KEY,student_id INTEGER,amount FLOAT, method TEXT, transactionID TEXT,mobile_used TEXT,date_paid TEXT,date_confirmed TEXT,mode TEXT,sms TEXT,entered_by INTEGER,status INTEGER ) ');

//       await db.execute(
//           'CREATE TABLE weeks ( week INTEGER PRIMARY KEY, paid INTEGER,) ');

//       await db.execute(
//           'CREATE TABLE videos ( id INTEGER PRIMARY KEY, title TEXT,  url TEXT, size TEXT, somo TEXT, type TEXT,) ');

//       await db.execute(
//           'CREATE TABLE notes ( id INTEGER PRIMARY KEY, title TEXT,  url TEXT, size TEXT, somo TEXT, type TEXT,) ');

//       await db.execute(
//           'CREATE TABLE zoezi ( id INTEGER PRIMARY KEY, title TEXT,  url TEXT, size TEXT, somo TEXT, type TEXT,) ');
//       await db.execute(
//           'CREATE TABLE savedvideos ( id INTEGER PRIMARY KEY, title TEXT,  url TEXT, size TEXT, somo TEXT, type TEXT,) ');
//     });
//   }

//   void insertUser(data) async {
//     await db.insert(
//       'user',
//       data.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }

//   void insertStudents(data) async {
//     await db.insert(
//       'students',
//       data.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }

//   void insertSavedvideos(data) async {
//     await db.insert(
//       'savedvideos',
//       data.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }

//   Future<void> insertPayments(data) async {
//     db.transaction((txn) async {
//       Batch batch = txn.batch();
//       for (var pays in data) {
//         Map row = pays;
//         batch.insert('payments', row);
//       }
//       batch.commit(noResult: true);
//     });
//   }

//   Future<void> insertWeeks(data) async {
//     db.transaction((txn) async {
//       Batch batch = txn.batch();
//       for (var pays in data) {
//         Map row = pays;
//         batch.insert('weeks', row);
//       }
//       batch.commit(noResult: true);
//     });
//   }

//   Future<void> insertVideos(data) async {
//     db.transaction((txn) async {
//       Batch batch = txn.batch();
//       for (var pays in data) {
//         Map row = pays;
//         batch.insert('videos', row);
//       }
//       batch.commit(noResult: true);
//     });
//   }

//   Future<void> insertNotes(data) async {
//     db.transaction((txn) async {
//       Batch batch = txn.batch();
//       for (var pays in data) {
//         Map row = pays;
//         batch.insert('notes', row);
//       }
//       batch.commit(noResult: true);
//     });
//   }

//   Future<void> insertZoezi(data) async {
//     db.transaction((txn) async {
//       Batch batch = txn.batch();
//       for (var pays in data) {
//         Map row = pays;
//         batch.insert('zoezi', row);
//       }
//       batch.commit(noResult: true);
//     });
//   }

//   map(data) {
//     return data as String;
//   }

//   // Fetching data to DB

//   Future getUser() async {
//     final maps = await db.query('user');
//     return maps as String;
//   }

//   Future getStudent() async {
//     final maps = await db.query('students');
//     return maps;
//   }

//   Future getPayments() async {
//     final maps = await db.query('payments');
//     return maps;
//   }

//   Future getWeeks() async {
//     final maps = await db.query('weeks');
//     return maps;
//   }

//   Future getVideos() async {
//     final maps = await db.query('videos');
//     return maps;
//   }

//   Future getNotes() async {
//     final maps = await db.query('notes');
//     return maps;
//   }

//   Future getZoezi() async {
//     final maps = await db.query('students');
//     return maps;
//   }

//   Future getSavedvideos() async {
//     final maps = await db.query('savedvideos');
//     return maps;
//   }
// }
