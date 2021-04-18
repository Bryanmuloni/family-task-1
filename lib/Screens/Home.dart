import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Models/expense_model.dart';

const String expensesBoxName = 'expenses';

class Home extends StatefulWidget {
  final formKey = GlobalKey<FormState>();
  Home({Key key, this.title});

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String itemName;
  DateTime date;
  String description;
  double price;
  int quantity;
  Payment payment;

  //
  final descriptionController = TextEditingController();
  final quanityController = TextEditingController();
  final itemNameController = TextEditingController();
  final priceController = TextEditingController();
  final dateController = TextEditingController();
  DateTime pickedDate;

  //
  final List<ExpenseModel> expenseItems = [
    ExpenseModel(
        // id: 'ID1',
        date: DateTime.now(),
        description: 'Officiis ipsam impedit et mollitia earum.',
        itemName: 'Watch',
        price: 150,
        quantity: 2),
    ExpenseModel(
        // id: 'ID2',
        date: DateTime.parse("2020-08-17 20:18:04Z"),
        description: 'Commodi rerum accusantium eos quis totam optio.',
        itemName: 'Shoes',
        price: 279,
        quantity: 1),
    ExpenseModel(
        // id: 'ID3',
        date: DateTime.parse("2020-08-16 20:18:04Z"),
        description: 'Veniam qui consequatur odio qui est dolorums.',
        itemName: 'Window Blinds',
        price: 405,
        quantity: 2),
  ];

  @override
  Widget build(BuildContext context) {
    //

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_downward),
            onPressed: () {
              expenseItems.sort((a, b) => a.itemName.compareTo(b.itemName));

              setState(() {
                expenseItems.forEach((expense) => print(expense.itemName));
              });
            },
          )
        ],
      ),
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DISPLAYING OUR WEEKLY CHARTS
          Container(
            width: double.infinity,
            child: Container(
              height: 150,
              child: Card(
                child: Text('Weekly Charts Display'),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable:
                Hive.box<ExpenseModel>(expensesBoxName).listenable(),
            builder: (context, Box<ExpenseModel> box, _) {
              if (box.values.isEmpty)
                return Center(
                  child: Text("No contacts"),
                );
              return ListView.builder(
                itemCount: box.values.length,
                itemBuilder: (context, index) {
                  ExpenseModel currentExpense = box.getAt(index);
                  String payment = paymentString[currentExpense.payment];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onLongPress: () {/* ... */},
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 5),
                            Text(currentExpense.itemName),
                            SizedBox(height: 5),
                            Text(currentExpense.description),
                            SizedBox(height: 5),
                            Text("Price: ${currentExpense.price}"),
                            SizedBox(height: 5),
                            Text("Payment: $payment"),
                            SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FOR EDITING AN EXISTING ITEM
          FloatingActionButton(
            child: Icon(Icons.edit),
            onPressed: () {},
          ),

          // CREATING SPACE
          SizedBox(
            height: 20,
          ),

          // FOR ADDING NEW EXPENSE ON THE LIST
          FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                showDialog(
                    context: (context),
                    builder: (_) {
                      return Dialog(
                          child: Container(
                        padding: const EdgeInsets.all(10),
                        // height: 520,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'New Item',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5.0),
                              _buildInputField(
                                  'Item Name', 'value', 'itemName'),
                              _buildInputField(
                                  'Description', 'value', 'description'),

                              // PRICE INPUT
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: Colors.grey)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,

                                      // autofocus: true,
                                      initialValue: "",
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          labelText: 'Price'),
                                      onChanged: (value) {
                                        setState(() {
                                          price = double.parse(value);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              // QUANTITY INPUT
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  // autofocus: true,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Quantity'),
                                  onChanged: (value) {
                                    setState(() {
                                      quantity = int.parse(value);
                                    });
                                  },
                                ),
                              ),

                              TextField(
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Pick your date'),
                                readOnly: true,
                                controller: dateController,
                                //decoration: InputDecoration(hintText: 'Pick your Date'),
                                onTap: () async {
                                  var date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime(2100));
                                  dateController.text =
                                      date.toString().substring(0, 10);
                                },
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              //
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 10.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Colors.grey,
                                    )),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Payment>(
                                    items:
                                        paymentString.keys.map((Payment value) {
                                      return DropdownMenuItem<Payment>(
                                        value: value,
                                        child: Text(paymentString[value]),
                                      );
                                    }).toList(),
                                    value: payment,
                                    hint: Text('Payment'),
                                    onChanged: (value) {
                                      setState(() {
                                        payment = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),

                              // INPUT BUTTON
                              Center(
                                child: ElevatedButton(
                                  onPressed: onFormSubmit,
                                  child: Center(
                                    child: Text('Add'),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ));
                    });
              }),
        ],
      ),
    );
    //
  }

  Widget _buildInputField(String label, String value, String labelName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        // autofocus: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
        onChanged: (value) {
          setState(() {
            labelName = value;
          });
        },
      ),
    );
  }

  //
  void onFormSubmit() {
    Box<ExpenseModel> expensesBox = Hive.box<ExpenseModel>(expensesBoxName);
    expensesBox.add(
      ExpenseModel(
          date: date,
          description: description,
          payment: payment,
          price: price,
          itemName: itemName,
          quantity: quantity),
    );
    Navigator.of(context).pop();
    print(expensesBox);
  }
}