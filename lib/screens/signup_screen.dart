import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_app/components/components.dart';
import 'package:final_app/components/under_part.dart';
import 'package:final_app/constants.dart';
import 'package:final_app/screens/screens.dart';
import 'package:final_app/widgets/widgets.dart';

final eController = TextEditingController();
final pController = TextEditingController();

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

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
                          child: Column(
                            children: [
                              // const RoundedInputField(
                              //     hintText: "Email", icon: Icons.email),

                              TextFieldContainer(
                                child: TextFormField(
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
                                    try {
                                      await FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                              email: eController.text.trim(),
                                              password:
                                                  pController.text.trim());
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginScreen()));
                                    } on FirebaseAuthException catch (e) {
                                      print(e);
                                    }
                                  }),

                              const SizedBox(
                                height: 10,
                              ),
                              UnderPart(
                                title: "Already have an account?",
                                navigatorText: "Login here",
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen()));
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
