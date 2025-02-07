import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/widgets/dialog.dart';
import 'package:cuentas_android/widgets/toast.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

    cuentaDao().getDatos(kIsWeb);
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
    TextEditingController email = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("He olvidado mi contraseña"),
              content: Expanded(
                child: TextField(
                  controller: email,
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
                    onPressed: () => rememberPassword(email.text),
                    child: const Text("Enviar"))
              ],
            ));
  }

  Widget loginRegister() => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
              height: 200, child: Image.asset(getImageUri(ImageUris.logo))),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Card(
                color:
                    GetColor(ColorTypes.secondary, context).withOpacity(0.94),
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                            style: TextStyle(
                                color: GetColor(ColorTypes.text, context),
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            isLogin ? '¡Hola de nuevo!' : '¡Encantado!'),
                        const SizedBox(
                          height: 10,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: _emailCOntroller,
                          decoration: InputDecoration(
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 10),
                              label: Text(
                                  style: TextStyle(
                                      color:
                                          GetColor(ColorTypes.text, context)),
                                  'Email'),
                              prefixIcon: Icon(
                                  color: GetColor(ColorTypes.text, context),
                                  Icons.email_rounded)),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          obscureText: true,
                          controller: _passwordCOntroller,
                          decoration: InputDecoration(
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 10),
                              label: Text(
                                  style: TextStyle(
                                      color:
                                          GetColor(ColorTypes.text, context)),
                                  'Contraseña'),
                              prefixIcon: Icon(
                                  color: GetColor(ColorTypes.text, context),
                                  Icons.password_rounded)),
                        ),
                        !isLogin
                            ? const SizedBox(
                                height: 10,
                              )
                            : Container(),
                        !isLogin
                            ? TextField(
                                controller: _repPasswordCOntroller,
                                decoration: InputDecoration(
                                    labelStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10),
                                    label: Text(
                                        style: TextStyle(
                                            color: GetColor(
                                                ColorTypes.text, context)),
                                        'Repetir contraseña'),
                                    prefixIcon: Icon(
                                        color:
                                            GetColor(ColorTypes.text, context),
                                        Icons.password_rounded)),
                              )
                            : Container(),
                        !isLogin
                            ? const SizedBox(
                                height: 10,
                              )
                            : Container(),
                        !isLogin
                            ? Center(
                                child: TextButton(
                                  onPressed: showEmailResetDialog,
                                  child: Text(
                                      style: TextStyle(
                                          color: GetColor(
                                              ColorTypes.text, context),
                                          decoration: TextDecoration.underline),
                                      'No recuerdo mi contraseña'),
                                ),
                              )
                            : Container()
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: CardButton(
                    color: GetColor(ColorTypes.primary, context),
                    onPressed: isLogin
                        ? () => signIn()
                        : () => setState(() {
                              isLogin = true;
                            }),
                    child: Text(
                        style: TextStyle(
                            color: GetColor(ColorTypes.text, context)),
                        isLogin ? 'Iniciar sesion' : 'Ya tengo cuenta'),
                    context: context),
              ),
              Expanded(
                flex: 5,
                child: CardButton(
                    color: GetColor(ColorTypes.primary, context),
                    onPressed: !isLogin
                        ? () => registerUser()
                        : () => setState(() {
                              isLogin = false;
                            }),
                    //child: Obx(()=> Text(Values().fondo.value)),
                    child: Text(
                        style: TextStyle(
                            color: GetColor(ColorTypes.text, context)),
                        isLogin ? 'Crear cuenta' : 'Registrarme'),
                    context: context),
              ),
            ],
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    // Auth().signInEmailPassword(
    //     email: "eneko12rebollo@gmail.com", password: "test12345");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: GetColor(ColorTypes.background, context),
          resizeToAvoidBottomInset: true,
          body: loginRegister()),
    );
  }
}
