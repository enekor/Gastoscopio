'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "f89db28227ec48576c4247890b4446f8",
"main.dart.js": "ac9b365fa1c2a0dae2c345e390b0e528",
".git/config": "ea231b5daa764e157f49e15372cb9a12",
".git/objects/e1/eb36a6783ad4f07f424f79626780a2f3ac1474": "dcd99d444ca6df28eb23d2af1e9f1bba",
".git/objects/3b/b0860a0981211a1ab11fced3e6dad7e9bc1834": "3f00fdcdb1bb283f5ce8fd548f00af7b",
".git/objects/63/781f30e192816e303af0f05b0c9b96718526a4": "b76055393f07f68f87d6ebb9b368e779",
".git/objects/02/cee74e159aefcc68446fa9ea0d32a9fce88c94": "a96f3d0d9f45323db027848a9e746702",
".git/objects/78/df7877ad3656b9d86420f881cf2ce5bfd85411": "bb6d905ba475c0b94be3f1333fce11f1",
".git/objects/78/ad4cc6a7034edf81d7152add51d0e8bacf8974": "1c05df5d4075549af747026d010e24e0",
".git/objects/6f/75205a242b8cdc8dc72fe9b091759cf02e3488": "b96fed95b64e084023c7ddeaa35ef179",
".git/objects/84/712272215c51757163bbae1ee44ecec5f85acb": "91ce09541677b8ff1a2443f22d571979",
".git/objects/70/a234a3df0f8c93b4c4742536b997bf04980585": "d95736cd43d2676a49e58b0ee61c1fb9",
".git/objects/f4/ebae7c665bb7a67425b109dbc6ddaaefb08dfd": "6ab0583ad7c1e28009e53007a23aa22e",
".git/objects/b7/7b5c372400bf81de029cc0bfd792a336a89902": "ad118502fab2ebdd27a8ff24f92fedf0",
".git/objects/f9/ebef1db32eecdc1c89eaa9ba97b28ef70a4e69": "1a5dcbef595fb6496214414a17a9bd39",
".git/objects/1f/a887b09706f2097312850f28130c59e784d812": "a2d29c6503c1f4ce1244469c4eea9089",
".git/objects/ef/bbfa76fc86f7b859a1d27a1a2135a87a081db2": "9d1e7b11d42e58b8b7ac13058a48875e",
".git/objects/6e/2036170ad83d12670976bb940e5f06b378bb0b": "cc76f9f3ab7e34644498281dd0661ad6",
".git/objects/6e/15e025e1c41af0c02a92e4c81a1c1c811e94b2": "8420c458dcc74cab0fdf22876b90485a",
".git/objects/82/ff2d9f20402003458b748002347f48a653164f": "6ff4b323315df852ec220e81993c69b2",
".git/objects/38/f72c3b661274731c0dca4263c6147292c3313e": "06ec909689545717240ec77454003efe",
".git/objects/75/80151663638adc0c059aa28b68ea817b158fbb": "09bf19e723de6d38d9e61eb3dacd89c8",
".git/objects/e0/6e77c6c883c9276a1f17eede61c4ef119607d0": "dd68af7cfddafb15e9c24309c2d31504",
".git/objects/4d/a3a100a489bb540966ae11cef2ef4b08490fee": "6b083b3faa296a6731b4dff560cdc898",
".git/objects/25/ccec822415993d4d8df0de3dd334634f16a3d9": "b2b0276358f2ac0601d2b76a8fabf283",
".git/objects/2d/0471ef9f12c9641643e7de6ebf25c440812b41": "d92fd35a211d5e9c566342a07818e99e",
".git/objects/5e/bf37944a56f2b5e479e3858392c6e9030da2da": "d874f5ce1eb6512c7b77ebd17b676f00",
".git/objects/f7/93331d320e35d13153d20a6c9e3f84dd255c2e": "e6339704d293be0cd4dc35c1850e7d20",
".git/objects/3c/a2a777481497b8ce34328dad56ab3f53aac83f": "9d7b9713e4247e85d0ffa50a4d90b6e0",
".git/objects/50/d46a672663d97af0ad90242c8456f65f68afdd": "9989131325e17852643c4247f9b305c1",
".git/objects/9d/6fcf31e67182e19f837c67f0392cbd889595dd": "3e9f4b8390c658c169c42fae3ab51dc6",
".git/objects/20/e0dfd52c4217c5e21edf4d02b8cd04b48c08ab": "d14996f2f209820ab25c08eedfd1d0e6",
".git/objects/20/6aa4ada75714e2df6709c7b51bc1276c191388": "66f3be8d7c9e195e0ac70b5829e68407",
".git/objects/76/4fac1ae993d3726ce1b6d2fe550eb45c64f161": "d6bca9eeeec1098f4df9633075be6a8c",
".git/objects/f2/392a464f3770c3758ccf5b6912635f196abb6b": "005a60338458497b1028723e61ab50b3",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/c1/3fc62510116d51c9285a78cf763ca2194ace2d": "b6568d1e98dabc5d304633e48c5b820f",
".git/objects/43/ed08b89a4e3a517f9cea503a84c1bd8c968490": "a9e52972dcd66e7d0afe8f03b7e0e39b",
".git/objects/43/c2fbb93918758bb2d29669cce3c269888bdba2": "bfd37be19f277770b0c011fc9b23ab55",
".git/objects/06/5a156ad876ae75d08bca0aabc8c1e01f285abb": "1338ac20d12542d14345378e2fe2be26",
".git/objects/9b/d3accc7e6a1485f4b1ddfbeeaae04e67e121d8": "784f8e1966649133f308f05f2d98214f",
".git/objects/ce/e3c5bb4ad9ca1b7e02e3391cc1cbba998308b7": "8e23cc0d8eea61c17a30b19ec3ccb417",
".git/objects/dc/67dd363b44f82d30dc9bd7cf661744278f4dd3": "fedc759dd4ef5de29d7b523f1c03f1a6",
".git/objects/57/20ed7820c397c4062e793f8c426befbb12ab5e": "78f6a7f5e47257a4b749601fa06ddf87",
".git/objects/79/b0fab3968957db6be3b1bd06574aa45918e8b9": "2abe5dcd07d45f616ffc5ca6aab7ed9c",
".git/objects/79/f1559e0851c4d32ab1b7bb01bfee5e0a066246": "7e80a7441134240db5687028e15af387",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/95/3294ea97a48b43bca77b9d520b9f0eafb50db5": "860db4c6c367dd5ec2541fdecd7b3dc8",
".git/objects/86/a90168ae8b5f9ec67e0c5285e171f408039f36": "d4c03b159abffef416278ecd315b22ba",
".git/objects/c7/0ce0b59be89eac3cd4a9d6ebdd3fd46a2f950b": "cede7dbf5767bd25e24454bacc72cdb9",
".git/objects/c7/7663172ca915a99a594ca17d06f527db05657d": "6335b074b18eb4ebe51f3a2c609a6ecc",
".git/objects/8f/0b7ba40650dc8403cef89eb535492c1f231015": "b029b304c3d44c25da999f87f00272a8",
".git/objects/c5/194847807488f06293f0cd6d83aa872931e9a4": "79cff79a4ec4ea17eb968fe4d9d0526e",
".git/objects/ad/c8949769391e4a89e1e63080a07fb716fb0caa": "79df5349d5e723a311a049f103d9b340",
".git/objects/07/cc3b4a614883e9dc8280c6c230de84bc2d3368": "68f06d966fab41a1ddd42ce6ca1a2e98",
".git/objects/e7/9bd831bec6592a53a20170a4d10f0571201d17": "d5b2db566a8f313d167e5b2aa1edb178",
".git/objects/00/a8bd5e86b29956cb5a2ce66618b104f5ca9534": "cb1964aaf84827a0794b8cd440e25739",
".git/objects/34/4bbd37b6edfa0252bf5099304cb83455c439c1": "7fe17b83b0ebc86eddcd76c88f877c77",
".git/objects/56/cbdb0f84ad1e63db3bf7595dbbcf52769790bd": "c0c54b5a7768d3a5390a357cc4779dd2",
".git/objects/6d/72dca7e861e03e15a5400c2d6bc25f30a5b96e": "023d49bb7e9c3c7d29683573d5252266",
".git/objects/40/4c0b0aba043ddb08d077d96ff1bd12bb901d43": "cbfffe1bc18fac0a5ae6f5f631bf8ad3",
".git/objects/4e/4c2326e68458082dda1090881726a0629d6aa3": "6d9dbae1df4c82e464e85b4975bff38d",
".git/objects/19/8c6afedcb749dafac0070a0a47049419dd3d6e": "41fc4f95cc97a28e8119b7f1df2a84ac",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/refs/remotes/origin/gh-pages": "6a49b7f1e34251c7c4ed9689ef3366db",
".git/refs/heads/gh-pages": "6a49b7f1e34251c7c4ed9689ef3366db",
".git/COMMIT_EDITMSG": "f0f6ec21ba2ed5823b66f668496c375e",
".git/index": "92ea204ed4ae060b599adc68c9b76dd1",
".git/logs/HEAD": "ecbad436909bc0645f9478f84b614089",
".git/logs/refs/remotes/origin/gh-pages": "514d881e4cb59507bda4d255cdc52e5a",
".git/logs/refs/heads/gh-pages": "ecbad436909bc0645f9478f84b614089",
"assets/FontManifest.json": "3ddd9b2ab1c2ae162d46e3cc7b78ba88",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "4769f3245a24c1fa9965f113ea85ec2a",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "3ca5dc7621921b901d513cc1ce23788c",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "a2eb084b706ab40c90610942d98886ec",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/fonts/MaterialIcons-Regular.otf": "ebc75c58980f7e822dd4ba442c11d5a4",
"assets/lib/assets/images/nuevo.png": "b3f093bf88148c4df57fcdd401cbb7d2",
"assets/lib/assets/images/background/noche2.jpeg": "b8446e41f378f560bd2136daadfd5cbf",
"assets/lib/assets/images/background/dia2.jpeg": "9f886def6d619e5de530401f31177efb",
"assets/lib/assets/images/background/dia1.jpeg": "d638984e9d0305b26b8bcfdb36843563",
"assets/lib/assets/images/background/noche1.jpeg": "0cd0d61b72225a3965b50a546cfa15a6",
"assets/lib/assets/images/background/tarde2.jpeg": "6566bc4b83d024f2b449a914b74131d8",
"assets/lib/assets/images/background/tarde1.jpeg": "f6b68999d2f6680aabe1d97407fbc817",
"assets/lib/assets/images/loading.gif": "90da552f0470e7382a4da8e9d2bdc865",
"assets/lib/assets/images/logo.svg": "42369fed4e5134675b8843d9cbd7e795",
"assets/lib/assets/images/logo.png": "07c84d54f98082a3797aee0e7243a4e8",
"assets/AssetManifest.json": "6a23cd8bf905aca5546ed689c30903aa",
"assets/NOTICES": "927b3b68ee5931e0d1cc2106652ab342",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "d05f0131ddba69a913ec9574819ffe11",
"assets/AssetManifest.bin": "c67f262cc0cc6059e49970fd1e855b26",
"assets.zip": "428f4f140c6e2bd3d388f4231bbd97fb",
"icons/Icon-maskable-512.png": "09065ee4299d318c3d968ecf23206337",
"icons/Icon-512.png": "09065ee4299d318c3d968ecf23206337",
"icons/Icon-192.png": "e5738599169168aabe6f86334b1c3307",
"icons/Icon-maskable-192.png": "e5738599169168aabe6f86334b1c3307",
"manifest.json": "b06ba19d0c1cbd8bab9a921177d78265",
"flutter_bootstrap.js": "ae5ad4acdba9dc92cae41e78c5aac1ab",
"index.html": "c1fea994e3e7631f6690e8d46cc9cd1e",
"/": "c1fea994e3e7631f6690e8d46cc9cd1e",
"version.json": "52bc46c70d623d446f49b816e65d2d9b",
"favicon.png": "07c84d54f98082a3797aee0e7243a4e8",
"canvaskit/skwasm.wasm": "a2021418f5cb63318cbe273e2e75f877",
"canvaskit/canvaskit.wasm": "1febcf3fdbbfb632728ab3902c386b44",
"canvaskit/chromium/canvaskit.wasm": "407d7dd73b05e38e5cafa7b789e22feb",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "9961e966e98a802d73942d48b15b86e7",
"canvaskit/skwasm.js": "ede049bc1ed3a36d9fff776ee552e414",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/skwasm.js.symbols": "6c749208f75e81d9628fa894d73bfbdc",
"canvaskit/canvaskit.js.symbols": "b7494490812ea0b4c2cbb3969019be96"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
