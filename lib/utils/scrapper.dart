import 'package:cuentas_android/models/product.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart';
import 'package:html/dom.dart';

Future<List<Product>> getData(String producto, int page, String orderBy) async {
  String url = "https://soysuper.com/search?q=$producto&page=$page$orderBy";

  final response = await http.get(Uri.parse(url));
  final document = parse(response.body);

  var ret = getProductFromShopAsync(url);
  return ret;
}

Future<List<Product>> getProductFromShopAsync(String shopUrl) async {
  final List<Product> products = [];
  final client = http.Client();

  try {
    final response = await client.get(Uri.parse(shopUrl));
    if (response.statusCode == 200) {
      final htmlContent = utf8.decode(response.bodyBytes);
      final document = parse(htmlContent);

      final ulNode = document.querySelector('ul[class*="basiclist"]');

      if (ulNode != null) {
        for (final liNode in ulNode.querySelectorAll('li')) {
          final liDocument = DocumentFragment.html(liNode.innerHtml);

          final productNode = liDocument.querySelector('a[class*="name"]');

          if (productNode != null) {
            final name = cleanString(liDocument
                .querySelector('span[class*="img"]')!
                .innerHtml
                .split('alt=')[1]
                .split('"')[1]);
            final description = cleanString(
                productNode.querySelector('span[class*="productname"]')!.text);

            final priceNode =
                liDocument.querySelector('span[class*="details"]');
            final price = extractValue(priceNode?.innerHtml ?? '');

            final imageNode = liDocument.querySelector('span[class*="img"]');
            final image = imageNode?.innerHtml.split('src=')[1].split('"')[1];

            final productUrlNode = liDocument.querySelector('a');
            final productUrl = productUrlNode?.attributes['href'];

            final supermarketUrl = Uri.parse(shopUrl).resolve(productUrl ?? '');
            final supermarketResponse = await client.get(supermarketUrl);
            if (supermarketResponse.statusCode == 200) {
              final supermarketContent =
                  utf8.decode(supermarketResponse.bodyBytes);
              final supermarketDocument = parse(supermarketContent);

              final supermarketNode = supermarketDocument
                  .querySelector('section[class*="superstable"] th');
              final shop =
                  supermarketNode?.innerHtml.split('title=')[1].split('"')[1];

              products.add(Product(name, description, price, image ?? '',
                  (supermarketUrl ?? '').toString(), shop ?? ''));
            } else {
              print('Error fetching supermarket details for $productUrl');
              continue; // Skip to the next product if supermarket details fail to load
            }
          }
        }
      } else {
        print('No <ul> element with class "basiclist" found.');
      }
    } else {
      print(
          'Error fetching products from $shopUrl (status code: ${response.statusCode})');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }

  return products;
}

String cleanString(String input) {
  return input
      .trim()
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

double extractValue(String input) {
  final pattern = RegExp(r'(\d+(\,\d+)?)€');
  final match = pattern.firstMatch(input);
  if (match != null) {
    return double.tryParse(
            match.group(1).toString().replaceAll(',', '.') ?? '') ??
        -1.0;
  }
  return -1.0;
}
