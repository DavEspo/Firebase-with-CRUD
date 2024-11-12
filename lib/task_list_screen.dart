import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';  // Assumed to be in your project (contains signOut method)
import 'task.dart';  // Assuming Task class is in task.dart (You need to create it)

/// Model for Time-based tasks (Daily/Hourly)
class TimeTask {
  String taskName;
  String startTime;
  String endTime;

  TimeTask({required this.taskName, required this.startTime, required this.endTime});
}

class DayTask {
  String dayName;
  List<TimeTask> timeTasks;

  DayTask({required this.dayName, required this.timeTasks});
}

/// Sample weekly tasks with daily and hourly breakdown
List<DayTask> weeklyTasks = [
  DayTask(dayName: 'Monday', timeTasks: [
    TimeTask(taskName: 'Homework 1', startTime: '9:00 AM', endTime: '10:00 AM'),
    TimeTask(taskName: 'Essay 2', startTime: '12:00 PM', endTime: '2:00 PM'),
  ]),
  DayTask(dayName: 'Tuesday', timeTasks: [
    TimeTask(taskName: 'Project Work', startTime: '10:00 AM', endTime: '12:00 PM'),
    TimeTask(taskName: 'Team Meeting', startTime: '2:00 PM', endTime: '3:00 PM'),
  ]),
  // Add tasks for other days...
];

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _taskController = TextEditingController();
  late FirebaseAuth _auth;
  late User _user;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;

    // Use authStateChanges instead of the deprecated onAuthStateChanged
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  // Add task to Firestore
  Future<void> _addTask() async {
    if (_taskController.text.isEmpty) return;

    final task = Task(
      id: DateTime.now().toString(),
      name: _taskController.text,
      isCompleted: false,
      userId: _user.uid,
    );

    await FirebaseFirestore.instance.collection('tasks').add(task.toMap());
    _taskController.clear();
  }

  // Toggle task completion
  Future<void> _toggleTaskCompletion(Task task) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
      'isCompleted': !task.isCompleted,
    });
  }

  // Delete task from Firestore
  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  // Display nested tasks (weekly view with daily/hourly tasks)
  Widget buildWeeklyTasks() {
    return ListView.builder(
      itemCount: weeklyTasks.length,
      itemBuilder: (context, dayIndex) {
        final dayTask = weeklyTasks[dayIndex];
        return ExpansionTile(
          title: Text(dayTask.dayName),
          children: dayTask.timeTasks.map((timeTask) {
            return ListTile(
              title: Text('${timeTask.taskName} (${timeTask.startTime} - ${timeTask.endTime})'),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(hintText: 'Enter task name'),
              autofocus: true,  // Ensure focus is on the text field
            ),
          ),
          ElevatedButton(
            onPressed: _addTask,
            child: Text('Add Task'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No tasks available.'));
                }

                final tasks = snapshot.data!.docs.map((doc) {
                  return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task.name),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) => _toggleTaskCompletion(task),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteTask(task.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(),  // Separator for weekly tasks
          Expanded(
            child: buildWeeklyTasks(),  // Display weekly tasks in a nested list
          ),
        ],
      ),
    );
  }
}