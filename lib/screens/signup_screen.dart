import 'package:email_validator/email_validator.dart';
import 'package:final_app/main.dart';
import 'package:final_app/widgets/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_app/components/components.dart';
import 'package:final_app/components/under_part.dart';
import 'package:final_app/constants.dart';
import 'package:final_app/screens/screens.dart';
import 'package:final_app/widgets/widgets.dart';

final eController = TextEditingController();
final pController = TextEditingController();

final formkey = GlobalKey<FormState>();

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  void dispose() {
    eController.dispose();
    pController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                const Upside(
                  imgUrl: "assets/images/electric-car.png",
                ),
                const PageTitleBar(title: 'Register Here'),
                Padding(
                  padding: const EdgeInsets.only(top: 305.0),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        // iconButton(context),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          "Use your email account",
                          style: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'OpenSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        Form(
                          key: formkey,
                          child: Column(
                            children: [
                              // const RoundedInputField(
                              //     hintText: "Email", icon: Icons.email),

                              TextFieldContainer(
                                child: TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (email) => email != null &&
                                          !EmailValidator.validate(email)
                                      ? 'Enter valid email'
                                      : null,
                                  controller: eController,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: kPrimaryColor,
                                  decoration: InputDecoration(
                                      icon: Icon(
                                        Icons.email,
                                        color: kPrimaryColor,
                                      ),
                                      hintText: "Email",
                                      hintStyle: const TextStyle(
                                          fontFamily: 'OpenSans'),
                                      border: InputBorder.none),
                                ),
                              ),

                              const RoundedInputField(
                                  hintText: "Name", icon: Icons.person),

                              // const RoundedPasswordField(),
                              TextFieldContainer(
                                child: TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (password) =>
                                      password != null && password.length < 6
                                          ? 'Enter password greate than 6 digit'
                                          : null,
                                  controller: pController,
                                  textInputAction: TextInputAction.next,
                                  obscureText: true,
                                  cursorColor: kPrimaryColor,
                                  decoration: const InputDecoration(
                                      icon: Icon(
                                        Icons.lock,
                                        color: kPrimaryColor,
                                      ),
                                      hintText: "Password",
                                      hintStyle:
                                          TextStyle(fontFamily: 'OpenSans'),
                                      suffixIcon: Icon(
                                        Icons.visibility,
                                        color: kPrimaryColor,
                                      ),
                                      border: InputBorder.none),
                                ),
                              ),

                              RoundedButton(
                                  text: 'REGISTER',
                                  press: () async {
                                    final isvalid =
                                        formkey.currentState!.validate();
                                    if (!isvalid) return;

                                    showDialog(
                                        context: context,
                                        builder: (context) => Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ));
                                    try {
                                      await FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                              email: eController.text.trim(),
                                              password:
                                                  pController.text.trim());
                                    } on FirebaseAuthException catch (e) {
                                      Utils.showShackBar(e.message);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen()),
                                      );
                                    }
                                    navigatorKey.currentState!
                                        .popUntil((route) => route.isFirst);
                                  }),

                              const SizedBox(
                                height: 10,
                              ),
                              UnderPart(
                                title: "Already have an account?",
                                navigatorText: "Login here",
                                onTap: () {
                                  navigatorKey.currentState!
                                      .popUntil((route) => route.isFirst);
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
