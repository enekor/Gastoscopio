import 'package:cuentas_android/models/product.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/widgets/productView.dart';
import 'package:flutter/material.dart';

Widget ShoppingCartView(List<Product> products, Function(Product) onUnCart) {
  return OrientationBuilder(
    builder: (context, orientation) => Padding(
        padding: EdgeInsets.only(
            top: 35,
            bottom: 15,
            right: orientation == Orientation.landscape ? 250 : 15,
            left: orientation == Orientation.landscape ? 250 : 15),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: orientation == Orientation.landscape ? 4 : 2,
            crossAxisSpacing: 3,
            childAspectRatio: 0.5,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return Container(
              child: ProductView(products[index], () {
                onUnCart(products[index]);
              }, fav: true),
            );
          },
        )),
  );
}

Widget ShoppingCartHasNotData() {
  return const Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.shopping_cart_checkout_rounded,
        color: Colors.grey,
        size: 50,
      ),
      Text(
        'No tienes productos en el carrito',
        style: TextStyle(color: Colors.grey),
      ),
    ],
  );
}
