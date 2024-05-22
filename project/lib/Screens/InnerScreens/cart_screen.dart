// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_single_cascade_in_expression_statements

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/Controllers/user_data.dart';
import 'package:project/Screens/InnerScreens/payment.dart';
import 'package:project/Widgets/inner_screen_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<int> priceList = [];
  int totalpp = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPrice();
  }

  // Future<void> setPrice() async {
  //   List<int> setPriceList = await getPrice();
  //   setState(() {
  //     priceList = setPriceList;
  //   });
  // }

  // void totalPrice() {
  //   for (int i = 0; i < priceList.length; i++) {
  //     total = total + priceList[i] as int;
  //     print(total);
  //   }
  // }

  User? user = FirebaseAuth.instance.currentUser;
  final _cartProductStream = FirebaseFirestore.instance.collection('users');

  UserData currentUser = new UserData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 5),
          child: Text('Cart Screen'),
        ),
        backgroundColor: Color.fromARGB(255, 151, 177, 139),
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black),
      ),
      bottomNavigationBar: Row(
        children: [
          // Text(
          //   "Total Amount",
          //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          // ),

          // Padding(
          //   padding: const EdgeInsets.only(left: 100),

          //   child: Text(

          //     'Rs.${totalpp}.00',
          //       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 1),
            child: ElevatedButton(
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return Center(
                            child: CircularProgressIndicator(
                          backgroundColor: Color.fromARGB(255, 0, 7, 1),
                          valueColor: new AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 243, 243, 244)),
                        ));
                      });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PaymentScreen(price: totalpp)),
                  );
                },
                style: ElevatedButton.styleFrom(
                    elevation: 20,
                    shadowColor: Colors.grey,
                    minimumSize: Size(280, 35)),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Icon(IconlyBold.buy),
                    ),
                    Text(
                      'Proceed to Payment',
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 20),
                    ),
                  ],
                )),
          )
        ],
      ),
      body: StreamBuilder(
          stream:
              _cartProductStream.doc(user!.uid).collection('cart').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading....');
            }
            var docs = snapshot.data;

            if (docs == null || docs.docs.isEmpty) {
              return Center(
                  child: const Text(
                'No cart items found',
                style: TextStyle(fontSize: 30),
              ));
            }

            List<Map<String, dynamic>> cartItems =
                docs.docs.map((doc) => doc.data()).toList();

            return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1, childAspectRatio: 800 / 360),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> data = cartItems[index];

                  String imgUrl =
                      data.containsKey('imageurl') ? data['imageurl'] : '';
                  String title = data.containsKey('title') ? data['title'] : '';
                  int price = data.containsKey('price')
                      ? int.tryParse(data['price'].toString()) ?? 0
                      : 0;
                  int discountPrice = data.containsKey('discountprice')
                      ? int.tryParse(data['discountprice'].toString()) ?? 0
                      : 0;

                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).cardColor,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(12),
                        child: Row(children: [
                          Image.network(
                            imgUrl,
                            height: 80,
                            fit: BoxFit.fill,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 1),
                                  child: Container(
                                    width: 80,
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1, vertical: 20),
                                  child: Container(
                                    width: 100,
                                    child: Text(
                                      'Rs.${price.toString()}.00',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .collection('cart')
                                  .doc(docs.docs[index].id)
                                  .delete();
                            },
                            icon: Icon(Icons.delete),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // PriceWidget(
                                //   isOnSale: true,
                                //   price: price,
                                //   salePrice: discountprice,
                                //   textPrice: _quantityTextController.text,
                                // ),
                                SizedBox(
                                  width: 8,
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                });
          }),
    );
  }

  void getPrice() async {
    List<int> priceList = await currentUser.getCurrentUserCartData();
    int newtotal = 0;
    for (int i = 0; i < priceList.length; i++) {
      newtotal = newtotal + priceList[i];
    }
    setState(() {
      totalpp = newtotal;
    });
  }
}
