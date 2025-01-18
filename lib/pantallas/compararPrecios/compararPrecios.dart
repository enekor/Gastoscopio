import 'package:cuentas_android/models/product.dart';
import 'package:cuentas_android/pantallas/compararPrecios/ShoppingCart.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:cuentas_android/widgets/views/compararPrecios/compararPreciosHome.dart';
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ActionChipButton(
                    text: const Text('Más barato'),
                    onPressed: () {
                      _orderBy.value = '&sort=value%3Aasc';
                    },
                    color: _orderBy.value == '&sort=value%3Aasc'
                        ? GetColor(ColorTypes.tertiary, context)
                        : GetColor(ColorTypes.secondary, context),
                  ),
                  ActionChipButton(
                    text: const Text('Más caro'),
                    onPressed: () {
                      _orderBy.value = '&sort=value%3Adesc';
                    },
                    color: _orderBy.value == '&sort=value%3Adesc'
                        ? GetColor(ColorTypes.tertiary, context)
                        : GetColor(ColorTypes.secondary, context),
                  ),
                ],
              ),
            ),
            Obx(
              () => ActionChipButton(
                text: const Text('Más populares'),
                onPressed: () {
                  _orderBy.value = '&sort=popularity%3Adesc';
                },
                color: _orderBy.value == '&sort=popularity%3Adesc'
                    ? GetColor(ColorTypes.tertiary, context)
                    : GetColor(ColorTypes.secondary, context),
              ),
            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GetColor(ColorTypes.background, context),
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: CompararPreciosAppBar(
          () => NavigateCart(context), Colors.transparent),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Obx(
          () => Container(
            decoration: Values().mostrarFondoDinamico.value
                ? BoxDecoration(
                    image: DecorationImage(
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3), BlendMode.darken),
                        image: AssetImage(Values().fondo.value),
                        fit: BoxFit.cover))
                : null,
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: CompararPreciosHomeHasData(_onCart, _orderBy.value,
                  (onSort) => _showSort(context, onSort), _isInCart),
            ),
          ),
        ), // Your content here
      ),
    );
  }
}
