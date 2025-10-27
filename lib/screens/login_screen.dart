import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  bool _isLoading = false; // 3.1 Estado de carga

  // Cerebro de la lógica de las animaciones
  StateMachineController? controller;
  SMIBool? isChecking;
  SMIBool? isHandsUp;
  SMITrigger? trigSuccess;
  SMITrigger? trigFail;
  SMINumber? numLook;

  // FocusNode
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  // Timer
  Timer? _typingDebounce;

  // Controllers
  final emailController = TextEditingController();
  final passController = TextEditingController();

  // 2.1 Cambiar a lista dinámica de errores
  List<String> _currentErrors = [];

  // 2.2 Validadores mejorados
  String? _validateEmail(String email) {
    if (email.isEmpty) return null; // No mostrar error si está vacío
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email) ? null : 'Email inválido';
  }

  String? _validatePassword(String pass) {
    if (pass.isEmpty) return null; // No mostrar error si está vacío

    final errors = <String>[];
    if (pass.length < 8) errors.add('Mínimo 8 caracteres');
    if (!RegExp(r'[A-Z]').hasMatch(pass)) errors.add('1 mayúscula');
    if (!RegExp(r'[a-z]').hasMatch(pass)) errors.add('1 minúscula');
    if (!RegExp(r'\d').hasMatch(pass)) errors.add('1 número');
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(pass))
      errors.add('1 caracter especial');

    return errors.isEmpty ? null : errors.first; // Solo el primer error
  }

  // 2.3 Función para actualizar errores en vivo
  void _updateErrors() {
    final errors = <String>[];

    final emailError = _validateEmail(emailController.text.trim());
    final passError = _validatePassword(passController.text);

    if (emailError != null) errors.add(emailError);
    if (passError != null) errors.add(passError);

    setState(() {
      _currentErrors = errors;
    });
  }

  // 1.1 Función de login mejorada con delay para Rive
  Future<void> _onLogin() async {
    if (_isLoading) return; // 3.2 Evitar spam

    // Cerrar teclado inmediatamente
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();

    // 3.3 ACTIVAR estado de carga YA para evitar double tap/spam
    // Deshabilita el botón inmediatamente mientras normalizamos y esperamos un frame
    setState(() {
      _isLoading = true;
    });

    // 1.2 Normalizar estado inmediatamente (bajar manos, apagar checking, centrar mirada)
    isHandsUp?.change(false);
    isChecking?.change(false);
    numLook?.value = 50.0;

    // 1.3 Esperar un frame para que Rive procese los cambios
    await Future.delayed(Duration.zero);

    // Validación final (actualiza _currentErrors)
    _updateErrors();

    // 1.4 Disparar triggers después de la normalización
    if (_currentErrors.isEmpty) {
      trigSuccess?.fire();
    } else {
      trigFail?.fire();
    }

    // 3.4 Simular carga y resetear (mantener spinner por ~1s)
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // 2.4 Listeners para validación en vivo
    emailController.addListener(_updateErrors);
    passController.addListener(_updateErrors);

    emailFocus.addListener(() {
      if (emailFocus.hasFocus) {
        isHandsUp?.change(false);
        numLook?.value = 50.0;
      }
    });

    passFocus.addListener(() {
      isHandsUp?.change(passFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/animated_login_character.riv',
                  stateMachines: ["Login Machine"],
                  onInit: (artboard) {
                    controller = StateMachineController.fromArtboard(
                      artboard,
                      "Login Machine",
                    );
                    if (controller == null) return;
                    artboard.addController(controller!);
                    isChecking = controller!.findSMI('isChecking');
                    isHandsUp = controller!.findSMI('isHandsUp');
                    trigSuccess = controller!.findSMI('trigSuccess');
                    trigFail = controller!.findSMI('trigFail');
                    numLook = controller!.findSMI('numLook');
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Campo Email
              TextField(
                focusNode: emailFocus,
                controller: emailController,
                onChanged: (value) {
                  isChecking?.change(true);
                  final look = (value.length / 100.0 * 100.0).clamp(0.0, 100.0);
                  numLook?.value = look;

                  _typingDebounce?.cancel();
                  _typingDebounce = Timer(
                    const Duration(milliseconds: 3000),
                    () {
                      if (mounted) isChecking?.change(false);
                    },
                  );
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  // 2.5 Solo mostrar error específico de email si existe
                  errorText:
                      _currentErrors.isNotEmpty &&
                          _currentErrors.first.contains('Email')
                      ? _currentErrors.first
                      : null,
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Campo Password
              TextField(
                focusNode: passFocus,
                controller: passController,
                onChanged: (value) {
                  isHandsUp?.change(true);
                },
                obscureText: _isObscure,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  // 2.6 Solo mostrar error específico de password si existe
                  errorText:
                      _currentErrors.isNotEmpty &&
                          !_currentErrors.first.contains('Email')
                      ? _currentErrors.first
                      : null,
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: size.width,
                child: const Text(
                  "Forgot your password?",
                  textAlign: TextAlign.right,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),

              const SizedBox(height: 10),

              // 3.5 Botón con estado de carga
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: _isLoading ? null : _onLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: _isLoading ? null : () {},
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}
