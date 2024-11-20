import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatScreen extends StatefulWidget {
  @override
  _AdminChatScreenState createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  String? selectedUserId;
  final TextEditingController _messageController = TextEditingController();

  Future<String> fetchUserName(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc('profile')
        .get();
    return userDoc.data()?['name'] ?? 'Unknown User';
  }

  Stream<QuerySnapshot> getUserChats() {
    return FirebaseFirestore.instance
        .collection('chats')
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(String userId, String message) async {
    if (message.trim().isEmpty) return;

    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(userId);

    await chatDoc.set({
      'lastMessage': message,
      'lastUpdated': FieldValue.serverTimestamp(),
      'unseenByUser': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await chatDoc.collection('messages').add({
      'senderId': 'admin',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isAdmin': true,
      'seen': false,
    });

    _messageController.clear();
  }

  Future<void> markMessagesAsSeen(String userId) async {
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(userId);
    await chatDoc.update({'unseenByAdmin': 0});

    final messages = await chatDoc
        .collection('messages')
        .where('seen', isEqualTo: false)
        .get();
    for (var message in messages.docs) {
      if (!(message['isAdmin'] as bool)) {
        await message.reference.update({'seen': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Text(
          'Admin Chat',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // User List
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.green.shade100,
              child: StreamBuilder<QuerySnapshot>(
                stream: getUserChats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user.id;
                      final unseenCount = user['unseenByAdmin'] ?? 0;

                      return FutureBuilder<String>(
                        future: fetchUserName(userId),
                        builder: (context, nameSnapshot) {
                          final userName = nameSnapshot.data ?? 'Loading...';

                          return Card(
                            color: userId == selectedUserId
                                ? Colors.green.shade300
                                : Colors.white,
                            child: ListTile(
                              title: Text(
                                userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(user['lastMessage'] ?? '',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: unseenCount > 0
                                  ? CircleAvatar(
                                      backgroundColor: Colors.red,
                                      radius: 12,
                                      child: Text(
                                        unseenCount.toString(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  selectedUserId = userId;
                                });
                                markMessagesAsSeen(
                                    userId); // Reset unseen count
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // Chat Screen
          Expanded(
            flex: 5,
            child: selectedUserId == null
                ? Center(
                    child: Text(
                      'Select a user to chat with.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade200,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: getMessagesStream(selectedUserId!),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              final messages = snapshot.data!.docs;

                              return ListView.builder(
                                reverse: true,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isAdmin = message['isAdmin'] as bool;

                                  return Align(
                                    alignment: isAdmin
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: EdgeInsets.all(8.0),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? Colors.green.shade100
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isAdmin
                                              ? Colors.green.shade600
                                              : Colors.grey.shade400,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        message['message'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isAdmin
                                              ? Colors.green.shade800
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.green.shade900,
                              child: IconButton(
                                icon: Icon(Icons.send, color: Colors.white),
                                onPressed: () => sendMessage(
                                    selectedUserId!, _messageController.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
