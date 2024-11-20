import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatScreen extends StatefulWidget {
  @override
  _AdminChatScreenState createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  String? selectedUserId;
  final TextEditingController _messageController = TextEditingController();

  // Fetch the user name based on UID
  Future<String> fetchUserName(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc('profile')
        .get();
    return userDoc.data()?['name'] ?? 'Unknown User';
  }

  // Stream to fetch all chats
  Stream<QuerySnapshot> getUserChats() {
    return FirebaseFirestore.instance
        .collection('chats')
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  // Stream to fetch messages of the selected user
  Stream<QuerySnapshot> getMessagesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Send a message from the admin
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

  // Mark all messages as seen by the admin
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
      appBar: AppBar(title: Text('Admin Chat')),
      body: Row(
        children: [
          // User List
          Expanded(
            flex: 2,
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

                        return ListTile(
                          title: Text(userName),
                          subtitle: Text(user['lastMessage'] ?? ''),
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
                            markMessagesAsSeen(userId); // Reset unseen count
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Chat Screen
          Expanded(
            flex: 5,
            child: selectedUserId == null
                ? Center(child: Text('Select a user to chat with.'))
                : Column(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: getMessagesStream(selectedUserId!),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
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
                                          ? Colors.green[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      message['message'],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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
                            IconButton(
                              icon: Icon(Icons.send, color: Colors.green),
                              onPressed: () => sendMessage(
                                  selectedUserId!, _messageController.text),
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
