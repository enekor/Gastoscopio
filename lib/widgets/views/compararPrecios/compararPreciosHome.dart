import 'package:cuentas_android/models/product.dart';
import 'package:cuentas_android/utils/scrapper.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/widgets/CProgressIndicator.dart';
import 'package:cuentas_android/widgets/productView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

RxMap<int, List<Product>> _products = RxMap<int, List<Product>>();
TextEditingController controller = TextEditingController();
RxString _busqueda = "".obs;
RxInt _pagina = 1.obs;
List<Product> _cart = [];
RxBool cargando = false.obs;
String _prevSearch = "";
List<int> _loadingPages = [];

void _buscar(String orderBy) async {
  if (_prevSearch != _busqueda.value) {
    _products.value.clear();
    _pagina.value = 1;
  }

  if (_busqueda.value.isNotEmpty) {
    if (!_products.value.containsKey(_pagina.value) &&
        !_loadingPages.contains(_pagina.value)) {
      cargando.value = true;
      _loadingPages.add(_pagina.value);
      _products.value[_pagina.value] =
          await getData(_busqueda.value, _pagina.value, orderBy);
      cargando.value = false;
      _loadingPages.remove(_pagina.value);
    }

    if (!_products.value.containsKey(_pagina.value + 1) &&
        !_loadingPages.contains(_pagina.value + 1)) {
      int paginaSiguiente = _pagina.value + 1;
      _loadingPages.add(paginaSiguiente);
      getData(_busqueda.value, _pagina.value + 1, orderBy).then((products) {
        _products.value[paginaSiguiente] = products;
        _loadingPages.remove(paginaSiguiente);
      });
    }

    _prevSearch = _busqueda.value;
  }

  _prevSearch = _busqueda.value;
}

Widget CompararPreciosHomeHasData(Function(Product) onCart, String orderBy,
    Function(Function(String) onSort) onSort, bool Function(Product) isInCart) {
  return Obx(
    () => Column(
      children: [
        // Cuadro de búsqueda y botón de buscar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(children: [
            IconButton(
                onPressed: () {
                  onSort((order) {
                    _products.value.clear();
                    _buscar(order);
                  });
                },
                icon: Icon(Icons.sort)),
            Expanded(
                child: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Producto"),
            )),
            IconButton(
                onPressed: () {
                  _busqueda.value = controller.text;
                  _buscar(orderBy);
                },
                icon: const Icon(Icons.search)),
          ]),
        ),
        _busqueda.value != ""
            ? Expanded(child: busquedaHasData(onCart, orderBy, isInCart))
            : Expanded(
                child: SizedBox(
                    child: Center(child: Text("Especifique un producto"))),
              )
      ],
    ),
  );
}

Widget busquedaHasData(
    Function(Product) onCart, String orderBy, bool Function(Product) isIncart) {
  return OrientationBuilder(
    builder: (context, orientation) => Obx(
      () => Padding(
        padding: EdgeInsets.symmetric(
            horizontal: orientation == Orientation.landscape ? 250 : 8.0),
        child: Column(children: [
          Expanded(
              child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (details) {
              if (details == DismissDirection.startToEnd) {
                // Deslizamiento a la derecha
                _pagina.value = _pagina.value == 1 ? 1 : _pagina.value - 1;
                _buscar(orderBy);
              } else if (details == DismissDirection.endToStart) {
                // Deslizamiento a la izquierda
                _pagina.value = _pagina.value + 1;
                _buscar(orderBy);
              }
            },
            background: _pagina.value == 1
                ? Container(color: Colors.transparent)
                : productPlaceholder(
                    onCart: onCart,
                    isIncart: isIncart,
                    pagina: _pagina.value - 1,
                    isLandscape: orientation == Orientation.landscape),
            secondaryBackground: productPlaceholder(
                onCart: onCart,
                isIncart: isIncart,
                pagina: _pagina.value + 1,
                isLandscape: orientation == Orientation.landscape),
            child: cargando.value
                ? CProgressIndicator()
                : productPlaceholder(
                    onCart: onCart,
                    isIncart: isIncart,
                    pagina: _pagina.value,
                    isLandscape: orientation == Orientation.landscape),
          )),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withAlpha(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    onPressed: () {
                      if (_pagina.value != 1) {
                        _pagina.value--;
                        _buscar(orderBy);
                      }
                    },
                    icon: const Icon(Icons.chevron_left)),
                Text(_pagina.value.toString()),
                IconButton(
                    onPressed: () {
                      _pagina.value++;
                      _buscar(orderBy);
                    },
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
        ]),
      ),
    ),
  );
}

Widget productPlaceholder(
    {required Function(Product) onCart,
    required bool Function(Product) isIncart,
    required int pagina,
    required bool isLandscape}) {
  return Obx(
    () => Padding(
        padding: const EdgeInsets.all(15),
        child: (_products.value.containsKey(pagina) &&
                _products[pagina]!.isNotEmpty)
            ? GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isLandscape ? 4 : 2,
                  crossAxisSpacing: 3,
                  childAspectRatio: 0.5,
                ),
                itemCount: _products.value[pagina]!.length,
                itemBuilder: (context, index) {
                  return Container(
                    child: ProductView(_products.value[pagina]![index], () {
                      onCart(_products.value[pagina]![index]);
                    }, GetColor(ColorTypes.secondary, context),
                        fav: isIncart(_products.value[pagina]![index])),
                  );
                },
              )
            : CProgressIndicator()),
  );
}

AppBar CompararPreciosAppBar(Function() onCart, Color color) {
  return AppBar(
    title: const Text('Comparar precios'),
    backgroundColor: color,
    centerTitle: true,
    actions: [
      IconButton(
          onPressed: onCart,
          icon: const Icon(Icons.shopping_cart_checkout_rounded))
    ],
  );
}
