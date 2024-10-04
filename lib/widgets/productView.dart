import 'package:cuentas_android/models/product.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

Widget ProductView(Product p, Function() onFav, Color color,{bool fav = false}) {
  RxBool favorito = fav.obs;

  return Obx(
    () => Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
        child: Center(
          child: Column(
            children: [
              Text(
                p.Name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(
                height: 15,
              ),
              Image.network(p.Image),
              Expanded(
                child: Center(
                  child: Text(
                    '${p.Price.toStringAsFixed(2)}€',
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(p.Shop),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: favorito.value
                            ? const Icon(Icons.shopping_cart)
                            : const Icon(Icons.shopping_cart_outlined),
                        onPressed: () {
                          onFav();
                          favorito.value = !favorito.value;
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next),
                        onPressed: () {
                          launchUrl(Uri.parse(p.Url));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
