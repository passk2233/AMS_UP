import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart'; // import assets ของคุณ
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AssetImages.login1), // ดึงรูปจากคลาสของคุณ
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double formWidth = constraints.maxWidth > 500
                            ? 400
                            : constraints.maxWidth;
                        return SizedBox(
                          width: formWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 40.0),
                              
                              // Topic Welcome
                              const Text(
                                'Welcome\nCEIT AMS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 60.0),

                              // Field User ID
                              const Text(
                                'User ID',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black87,
                                ),
                              ),
                              TextField(
                                controller: controller.usernameController,
                                decoration: const InputDecoration(
                                  hintText: 'please enter your User ID',
                                  hintStyle: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 14.0,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black87,
                                      width: 2.0,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24.0),

                              // Field Password
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black87,
                                ),
                              ),
                              Obx(() => TextField(
                                    controller: controller.passwordController,
                                    obscureText: controller.isObscured.value, // แก้จาก isObscured เป็น isObscure ตาม Controller
                                    decoration: InputDecoration(
                                      hintText: 'please enter your Password',
                                      hintStyle: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 14.0,
                                      ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black87,
                                          width: 2.0,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          controller.isObscured.value // แก้จาก isObscured
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                        onPressed: () => controller.toggleObscured(), // แก้จาก toggleObscured
                                      ),
                                    ),
                                  )),
                              const SizedBox(height: 10.0),

                              // Remember Me Checkbox
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Obx(() => Checkbox(
                                        value: controller.rememberMe.value,
                                        onChanged: (value) => controller.toggleRememberMe(value),
                                        activeColor: const Color(0xFF3B95B7),
                                        side: const BorderSide(color: Colors.black87),
                                      )),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),

                              // Login Button
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value ? null : () => controller.login(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B95B7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Obx(() => controller.isLoading.value
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        )),
                                ),
                              ),
                              const SizedBox(height: 40.0), // อันนี้คือ Widget ตัวสุดท้ายใน Column
                            ], // จบ List ของ children ตรงนี้พอดี!
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}