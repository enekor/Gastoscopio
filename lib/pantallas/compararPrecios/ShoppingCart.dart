import 'package:cuentas_android/models/product.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/widgets/views/compararPrecios/ShoppingCartWidgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShoppingCart extends StatelessWidget {
  ShoppingCart(List<Product> cart, {super.key}) {
    products = cart.obs;
  }

  RxList<Product> products = RxList<Product>();

  void _onUnCart(Product p) {
    products.value.remove(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: GetColor(ColorTypes.background, context),
        resizeToAvoidBottomInset: true,
        body: WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, products);
            return true;
          },
          child: Obx(() => SizedBox(
                height: MediaQuery.of(context).size.height,
                width: double.infinity,
                child: products.value.isNotEmpty
                    ? ShoppingCartView(products.value, _onUnCart)
                    : ShoppingCartHasNotData(),
              )),
        ));
  }
}
