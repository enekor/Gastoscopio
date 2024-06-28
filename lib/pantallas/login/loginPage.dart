import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/widgets/dialog.dart';
import 'package:cuentas_android/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;

  final TextEditingController _emailCOntroller = TextEditingController();
  final TextEditingController _passwordCOntroller = TextEditingController();
  final TextEditingController _repPasswordCOntroller = TextEditingController();

  Future signIn() async {
    try {
      await Auth().signInEmailPassword(
          email: _emailCOntroller.text, password: _passwordCOntroller.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        showYesNoDialog(
            title: "OAuth error",
            onYes: () {},
            context: context,
            body: Text(e.message!));
      });
    }
  }

  Future rememberPassword(String email) async {
    try {
      await Auth().rememberPassword(email);
      showToast(
          text: "Email enviado al correo $email", length: Toast.LENGTH_LONG);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        showYesNoDialog(
            title: "OAuth error",
            onYes: () {},
            context: context,
            body: Text(e.message!));
      });
    }
  }

  Future registerUser() async {
    if (_passwordCOntroller.text == _repPasswordCOntroller.text) {
      try {
        await Auth().registerWithUserPassword(
            email: _emailCOntroller.text, password: _passwordCOntroller.text);
      } on FirebaseAuthException catch (e) {
        setState(() {
          showYesNoDialog(
              title: "OAuth error",
              onYes: () {},
              context: context,
              body: Text(e.message!));
        });
      }
    } else {
      setState(() {
        showYesNoDialog(
            title: "OAuth error",
            onYes: () {},
            context: context,
            body: const Text("Las contraseñas no coinciden"));
      });
    }
  }

  bool _hidePass = true;
  void changeVisible() {
    setState(() {
      _hidePass = !_hidePass;
    });
  }

  void showEmailResetDialog() {
    TextEditingController _email = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("He olvidado mi contraseña"),
              content: Expanded(
                child: TextField(
                  controller: _email,
                  autofocus: true,
                  decoration:
                      const InputDecoration(labelText: "Email del usuario"),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar")),
                TextButton(
                    onPressed: () => rememberPassword(_email.text),
                    child: const Text("Enviar"))
              ],
            ));
  }

  Widget login() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 8,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: ClipOval(
                      child: Image.asset(
                        "lib/assets/images/logo.png",
                      ),
                    ),
                  ),
                  Text(
                    "Gastoscopio",
                    style: TextStyle(
                      color: GetColor(ColorTypes.icono, context),
                      fontSize: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Text("Iniciar sesión",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 35)),
              )),
          Expanded(
            flex: 8,
            child: Card(
                color: GetColor(ColorTypes.tertiary, context),
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.only(topRight: Radius.circular(100))),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Expanded(
                                      flex: 2,
                                      child: Icon(Icons.email_rounded)),
                                  Expanded(
                                    flex: 8,
                                    child: TextField(
                                      controller: _emailCOntroller,
                                      decoration: const InputDecoration(
                                        labelText: "Email",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Expanded(
                                      flex: 2, child: Icon(Icons.lock)),
                                  Expanded(
                                    flex: 8,
                                    child: TextField(
                                      obscureText: _hidePass,
                                      controller: _passwordCOntroller,
                                      decoration: InputDecoration(
                                          labelText: "Constraseña",
                                          suffixIcon: IconButton(
                                              onPressed: changeVisible,
                                              icon: Icon(_hidePass
                                                  ? Icons.visibility
                                                  : Icons.visibility_off))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: showEmailResetDialog,
                                style: const ButtonStyle(
                                    alignment: Alignment.center),
                                child: const Text("¿Olvidaste la contraseña?"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        GetColor(
                                            ColorTypes.secondary, context))),
                                onPressed: signIn,
                                child: const Text("Entrar")),
                            TextButton(
                                onPressed: () => setState(() {
                                      isLogin = false;
                                    }),
                                child: const Text("No tengo una cuenta"))
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          )
        ],
      );

  Widget register() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 8,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: ClipOval(
                      child: Image.asset(
                        "lib/assets/images/logo.png",
                      ),
                    ),
                  ),
                  Text(
                    "Gastoscopio",
                    style: TextStyle(
                      color: GetColor(ColorTypes.icono, context),
                      fontSize: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Text("Registrar",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 35)),
              )),
          Expanded(
            flex: 8,
            child: Card(
                color: GetColor(ColorTypes.tertiary, context),
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.only(topLeft: Radius.circular(100))),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Expanded(
                                      flex: 2,
                                      child: Icon(Icons.email_rounded)),
                                  Expanded(
                                    flex: 8,
                                    child: TextField(
                                      controller: _emailCOntroller,
                                      decoration: const InputDecoration(
                                        labelText: "Email",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Expanded(
                                      flex: 2, child: Icon(Icons.lock)),
                                  Expanded(
                                    flex: 8,
                                    child: TextField(
                                      obscureText: _hidePass,
                                      controller: _passwordCOntroller,
                                      decoration: InputDecoration(
                                          labelText: "Constraseña",
                                          suffixIcon: IconButton(
                                              onPressed: changeVisible,
                                              icon: Icon(_hidePass
                                                  ? Icons.visibility
                                                  : Icons.visibility_off))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Expanded(
                                      flex: 2, child: Icon(Icons.lock)),
                                  Expanded(
                                    flex: 8,
                                    child: TextField(
                                      obscureText: _hidePass,
                                      controller: _repPasswordCOntroller,
                                      decoration: InputDecoration(
                                          labelText: "Repetir constraseña",
                                          suffixIcon: IconButton(
                                              onPressed: changeVisible,
                                              icon: Icon(_hidePass
                                                  ? Icons.visibility
                                                  : Icons.visibility_off))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        GetColor(
                                            ColorTypes.secondary, context))),
                                onPressed: registerUser,
                                child: const Text("Login")),
                            TextButton(
                                onPressed: () => setState(() {
                                      isLogin = true;
                                    }),
                                child: const Text("Ya tengo una cuenta"))
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    //Auth().signInEmailPassword(
    //email: "test@gastoscopio.com", password: "admin1234");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: GetColor(ColorTypes.background, context),
          body: isLogin ? login() : register()),
    );
  }
}
