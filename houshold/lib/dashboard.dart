import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class MealsPage extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final Function(String, int, DateTime) onAdd;
  final Function(int) onRemove;

  MealsPage({required this.meals, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController quantityController = TextEditingController();
    TextEditingController expiryController = TextEditingController();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Meals',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Meal Name',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: expiryController,
              decoration: InputDecoration(
                labelText: 'Expiry Date (YYYY-MM-DD)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty &&
                    expiryController.text.isNotEmpty) {
                  onAdd(
                    nameController.text,
                    int.parse(quantityController.text),
                    DateTime.parse(expiryController.text),
                  );
                  nameController.clear();
                  quantityController.clear();
                  expiryController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Add Meal'),
            ),
            SizedBox(height: 20),
            meals.isEmpty
                ? Center(
                    child: Text(
                      'No meals added yet!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      var meal = meals[index];
                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.restaurant, color: Colors.white),
                          ),
                          title: Text(
                            meal['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Quantity: ${meal['quantity']}\nExpiry: ${meal['expiryDate'].toString().split(' ')[0]}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onRemove(index),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> groceries = [];
  List<Map<String, dynamic>> meals = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void addItem(List<Map<String, dynamic>> list, String name, int quantity,
      DateTime expiryDate) {
    setState(() {
      list.add({'name': name, 'quantity': quantity, 'expiryDate': expiryDate});
    });
    checkLowStock(list);
  }

  void removeItem(List<Map<String, dynamic>> list, int index) {
    setState(() {
      list.removeAt(index);
    });
  }

  void checkLowStock(List<Map<String, dynamic>> list) {
    List<Map<String, dynamic>> lowStockItems =
        list.where((item) => item['quantity'] <= 2).toList();
    if (lowStockItems.isNotEmpty) {
      sendNotification(
        "Low Stock Alert",
        "You are running low on items in ${list == groceries ? 'Groceries' : 'Meals'}.",
      );
    }
  }

  Future<void> sendNotification(String title, String body) async {
    var androidDetails = AndroidNotificationDetails('channelId', 'channelName',
        importance: Importance.high);
    var notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, notificationDetails);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(groceries: groceries, meals: meals),
      ItemList(
        title: 'Groceries',
        items: groceries,
        onAdd: (name, quantity, expiryDate) =>
            addItem(groceries, name, quantity, expiryDate),
        onRemove: (index) => removeItem(groceries, index),
      ),
      MealsPage(
        meals: meals,
        onAdd: (name, quantity, expiryDate) =>
            addItem(meals, name, quantity, expiryDate),
        onRemove: (index) => removeItem(meals, index),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Household Manager')),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Groceries'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Meals'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> groceries;
  final List<Map<String, dynamic>> meals;

  HomePage({required this.groceries, required this.meals});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Groceries',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 10),
            groceries.isEmpty
                ? Center(
                    child: Text(
                      'No groceries added yet!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Column(
                    children: groceries.map((item) {
                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child:
                                Icon(Icons.shopping_cart, color: Colors.white),
                          ),
                          title: Text(
                            item['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Quantity: ${item['quantity']}\nExpiry: ${item['expiryDate'].toString().split(' ')[0]}',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            SizedBox(height: 20),
            Text(
              'Meals',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 10),
            meals.isEmpty
                ? Center(
                    child: Text(
                      'No meals added yet!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Column(
                    children: meals.map((item) {
                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.restaurant, color: Colors.white),
                          ),
                          title: Text(
                            item['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Quantity: ${item['quantity']}\nExpiry: ${item['expiryDate'].toString().split(' ')[0]}',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class ItemList extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Function(String, int, DateTime) onAdd;
  final Function(int) onRemove;

  ItemList(
      {required this.title,
      required this.items,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController quantityController = TextEditingController();
    TextEditingController expiryController = TextEditingController();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: title == 'Groceries' ? Colors.teal : Colors.orange,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: expiryController,
              decoration: InputDecoration(
                labelText: 'Expiry Date (YYYY-MM-DD)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty &&
                    expiryController.text.isNotEmpty) {
                  onAdd(
                    nameController.text,
                    int.parse(quantityController.text),
                    DateTime.parse(expiryController.text),
                  );
                  nameController.clear();
                  quantityController.clear();
                  expiryController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    title == 'Groceries' ? Colors.teal : Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Add Item'),
            ),
            SizedBox(height: 20),
            items.isEmpty
                ? Center(
                    child: Text(
                      'No items added yet!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: title == 'Groceries'
                                ? Colors.teal
                                : Colors.orange,
                            child: Icon(
                              title == 'Groceries'
                                  ? Icons.shopping_cart
                                  : Icons.restaurant,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            item['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Quantity: ${item['quantity']}\nExpiry: ${item['expiryDate'].toString().split(' ')[0]}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onRemove(index),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
