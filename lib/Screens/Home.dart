import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
// import 'package:intl/intl.dart';

import '../Models/expense_model.dart';
import '../boxes.dart';

const String expensesBoxName = 'expenses';

class Home extends StatefulWidget {
  Home({Key key, this.title});

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var userInput = '';
  var result = '';

  Box<ExpenseModel> expensesBox;
  DateTime date;
  final itemNameController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final itemPriceController = TextEditingController();
  final itemQuantityController = TextEditingController();
  final dateController = TextEditingController();

  Payment payment;

  @override
  void dispose() {
    Hive.box('expenseModels').close();

    /// Todo: Always consider disposing off controllers to avoid memory leaks
    itemNameController.dispose();
    itemDescriptionController.dispose();
    itemPriceController.dispose();
    itemQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFFC6B5ED),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Expense App',
          style: GoogleFonts.alef(
            fontSize: 30,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => buildShowDialog(context),
          )
        ],
      ),
      body: Builder(
        builder: (context) => ValueListenableBuilder<Box<ExpenseModel>>(
          valueListenable: Boxes.getExpenses().listenable(),
          builder: (context, box, _) {
            //
            List keys = box.keys.cast<int>().toList();

            //* For Calculating the total expenses
            final netExpense = box.values.fold(
                0,
                (previousValue, element) => element.itemName.isNotEmpty
                    ? previousValue + element.price
                    : previousValue - element.price);

            final newExpenseString = '${netExpense.toStringAsFixed(2)}';
            final color = netExpense > 0 ? Colors.purple : Colors.red;
            if (box.values.isEmpty)
              Center(
                child: Text('No expenses added yet!'),
              );
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.13,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Total Expenses Made So Far:',
                        style: GoogleFonts.alef(
                            fontSize: 25, color: Colors.white70),
                      ),
                      Text(
                        '₦$newExpenseString',
                        style: GoogleFonts.roboto(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: color),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      //
                      final int key = keys[index];

                      final ExpenseModel currentExpense = box.get(key);
                      String payment = paymentString[currentExpense.payment];

                      return Dismissible(
                        background: redDismissibleContainer(),
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            setState(() {
                              box.deleteAt(index);
                              // showSnackBar(context);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('${currentExpense.itemName} Deleted!'),
                              ),
                            );
                          }
                        },
                        confirmDismiss: (DismissDirection direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Delete Confirmation"),
                                content: const Text(
                                    "Are you sure you want to delete this item?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Delete"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        key: ValueKey(keys),
                        child: InkWell(
                          onTap: () => buildShowDialogMenu(
                            context,
                            currentExpense,
                            index,
                            payment,
                          ),
                          child: Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: Column(
                                children: <Widget>[
                                  /* 
                                  Todo: This was showing errors because the item name and description
                                  where not saved in the box, consider checking for null values in
                                  Text Widgets to avoid null errors 
                                  */
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        currentExpense?.itemName ??
                                            "No name added",
                                        style: GoogleFonts.acme(
                                          fontSize: 25,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '₦${currentExpense.price}',
                                            style: GoogleFonts.roboto(
                                              fontSize: 20,
                                              color: Color(0xFF9D86DE),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat.yMMMEd()
                                            .format(currentExpense.date),
                                        style: GoogleFonts.acme(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.more_vert),
                                        onPressed: () {
                                          onUpdateDialog(
                                            context,
                                            index,
                                            currentExpense,
                                          );
                                        },
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    //
  }

  Future buildShowDialogMenu(BuildContext context, ExpenseModel currentExpense,
      int index, String payment) {
    Color textColor = Colors.white;
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
            padding: EdgeInsets.all(10),
            height: 300,
            color: Color(0xFF9D86DE),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(currentExpense.itemName[0].toUpperCase(),
                        style: GoogleFonts.acme(fontSize: 30)),
                  ),
                  Text(
                    currentExpense.itemName,
                    style: GoogleFonts.acme(fontSize: 35, color: textColor),
                  ),
                  Text(
                    currentExpense.description,
                    style: GoogleFonts.acme(fontSize: 20, color: textColor),
                  ),
                  Text(
                    'Payment Mode: $payment',
                    style: GoogleFonts.acme(fontSize: 20, color: textColor),
                  ),
                  Text(
                    'Created On:    ${DateFormat.yMMMMEEEEd().format(currentExpense.date)}',
                    style: GoogleFonts.acme(fontSize: 15, color: textColor),
                  ),
                  Text(
                    'Quantity: ${currentExpense.quantity}',
                    style: GoogleFonts.acme(fontSize: 20, color: textColor),
                  ),
                  Text(
                    'Cost Price:  ₦${currentExpense.price}',
                    style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  Future buildShowDialog(BuildContext context) {
    return showDialog(
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
                  SizedBox(height: 20.0),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      controller: itemNameController,
                      decoration: InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(height: 5.0),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      controller: itemDescriptionController,
                      decoration: InputDecoration(
                        labelText: "Item Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  // PRICE INPUT
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: itemPriceController,
                          keyboardType: TextInputType.number,
                          // autofocus: true,
                          // initialValue: "",
                          decoration: InputDecoration(
                              border: InputBorder.none, labelText: 'Price'),
                          // onChanged: (value) {
                          //   setState(() {
                          //     price = double.parse(value);
                          //   });
                          // },
                        ),
                      ),
                    ),
                  ),

                  // QUANTITY INPUT
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextField(
                      controller: itemQuantityController,
                      keyboardType: TextInputType.number,
                      // autofocus: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(), labelText: 'Quantity'),
                    ),
                  ),

                  SizedBox(
                    height: 15,
                  ),

                  // THE dropdown section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.grey,
                        )),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Payment>(
                        items: paymentString.keys.map((Payment value) {
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
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF9D86DE),
                      ),
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
  }

  //* EDITING
  Future onUpdateDialog(
      BuildContext context, int index, ExpenseModel currentExpense) {
    return showDialog(
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
                  SizedBox(height: 20.0),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      controller: itemNameController,
                      decoration: InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(height: 5.0),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      controller: itemDescriptionController,
                      decoration: InputDecoration(
                        labelText: "Item Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  // PRICE INPUT
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: itemPriceController,
                          keyboardType: TextInputType.number,
                          // autofocus: true,
                          // initialValue: "",
                          decoration: InputDecoration(
                              border: InputBorder.none, labelText: 'Price'),
                          // onChanged: (value) {
                          //   setState(() {
                          //     price = double.parse(value);
                          //   });
                          // },
                        ),
                      ),
                    ),
                  ),

                  // QUANTITY INPUT
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextField(
                      controller: itemQuantityController,
                      keyboardType: TextInputType.number,
                      // autofocus: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(), labelText: 'Quantity'),
                    ),
                  ),

                  SizedBox(
                    height: 15,
                  ),

                  // THE dropdown section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.grey,
                        )),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Payment>(
                        items: paymentString.keys.map((Payment value) {
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
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF9D86DE),
                      ),
                      onPressed: () {
                        onUpdate(index);
                      },
                      child: Center(
                        child: Text('Save'),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ));
        });
  }

  /// * This affects performance of the app, consider adding the fields directly

  void onFormSubmit() {
    Box<ExpenseModel> expensesBox = Hive.box<ExpenseModel>(expensesBoxName);

    expensesBox.add(
      ExpenseModel(
        date: DateTime.now(),
        description: itemDescriptionController.text,
        payment: payment,
        price: double.parse(itemPriceController.text),
        itemName: itemNameController.text,
        quantity: int.parse(
          itemQuantityController.text,
        ),
      ),
    );
    Navigator.of(context).pop();
    clearTextField();
  }

  //* Updating my expense
  void onUpdate(int index) {
    Box<ExpenseModel> expensesBox = Hive.box<ExpenseModel>(expensesBoxName);

    expensesBox.putAt(
      index,
      ExpenseModel(
        date: DateTime.now(),
        description: itemDescriptionController.text,
        payment: payment,
        price: double.parse(itemPriceController.text),
        itemName: itemNameController.text,
        quantity: int.parse(
          itemQuantityController.text,
        ),
      ),
    );
    Navigator.of(context).pop();
    clearTextField();
  }

  // * Clearing the TextField
  void clearTextField() {
    itemNameController.clear();
    itemDescriptionController.clear();
    itemPriceController.clear();
    itemQuantityController.clear();
  }

  Widget redDismissibleContainer() => Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 60.0),
        color: Colors.redAccent,
        child: Icon(Icons.delete, color: Colors.white, size: 50),
      );
}
