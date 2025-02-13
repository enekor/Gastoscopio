import 'package:cuentas_android/models/product.dart';
import 'package:cuentas_android/pantallas/compararPrecios/ShoppingCart.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/widgets/views/compararPrecios/compararPreciosHome.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompararPrecios extends StatelessWidget {
  CompararPrecios({super.key});

  final List<Product> _cart = [];
  RxString ret = "".obs;
  final RxString _orderBy = "".obs;

  bool _isInCart(Product p) {
    return _cart.contains(p);
  }

  void _onCart(Product p) {
    _cart.contains(p) ? _cart.remove(p) : _cart.add(p);
  }

  void NavigateCart(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (context) => ShoppingCart(_cart),
    ))
        .then((newCart) {
      _cart.clear();
      _cart.addAll(newCart as List<Product>);
    });
  }

  void _showSort(BuildContext context, Function(String) onSelectSort) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(15.0),
        child: Obx(
          () => Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ActionChipButton(
                      selected: _orderBy.value == '&sort=value%3Aasc',
                      text: 'Más barato',
                      onPressed: () {
                        _orderBy.value = '&sort=value%3Aasc';
                      }),
                  ActionChipButton(
                      selected: _orderBy.value == '&sort=value%3Adesc',
                      text: 'Más caro',
                      onPressed: () {
                        _orderBy.value = '&sort=value%3Adesc';
                      }),
                ],
              ),
              ActionChipButton(
                  selected: _orderBy.value == '&sort=popularity%3Adesc',
                  text: 'Más populares',
                  onPressed: () {
                    _orderBy.value = '&sort=popularity%3Adesc';
                  }),
              Center(
                child: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () {
                    onSelectSort(_orderBy.value);
                    Navigator.pop(context);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: CompararPreciosAppBar(
          () => NavigateCart(context), Colors.transparent),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.only(top: 80.0),
            child: CompararPreciosHomeHasData(_onCart, _orderBy.value,
                (onSort) => _showSort(context, onSort), _isInCart),
          ),
        ), // Your content here
      ),
    );
  }
}
