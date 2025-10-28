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
  bool _isLoading = false;
  bool _emailInteracted = false;
  bool _passInteracted = false;

  StateMachineController? controller;
  SMIBool? isChecking;
  SMIBool? isHandsUp;
  SMITrigger? trigSuccess;
  SMITrigger? trigFail;
  SMINumber? numLook;

  final emailFocus = FocusNode();
  final passFocus = FocusNode();
  Timer? _typingDebounce;

  final emailController = TextEditingController();
  final passController = TextEditingController();

  String? _emailError;

  // 1.1 Variables para el checklist de contraseña
  final Map<String, bool> _passwordValidation = {
    'Mínimo 8 caracteres': false,
    '1 mayúscula': false,
    '1 minúscula': false,
    '1 número': false,
    '1 caracter especial': false,
  };

  // 1.2 Validación de email
  String? _validateEmail(String email) {
    if (email.isEmpty) return 'El email es requerido';
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email) ? null : 'Email inválido';
  }

  // 1.3 Validación mejorada de contraseña con checklist
  void _validatePassword(String pass) {
    setState(() {
      _passwordValidation['Mínimo 8 caracteres'] = pass.length >= 8;
      _passwordValidation['1 mayúscula'] = RegExp(r'[A-Z]').hasMatch(pass);
      _passwordValidation['1 minúscula'] = RegExp(r'[a-z]').hasMatch(pass);
      _passwordValidation['1 número'] = RegExp(r'\d').hasMatch(pass);
      _passwordValidation['1 caracter especial'] = RegExp(
        r'[^A-Za-z0-9]',
      ).hasMatch(pass);
    });
  }

  // 1.4 Verificar si la contraseña es completamente válida
  bool get _isPasswordValid {
    return _passwordValidation.values.every((isValid) => isValid);
  }

  void _updateEmailError() {
    if (_emailInteracted) {
      setState(() {
        _emailError = _validateEmail(emailController.text.trim());
      });
    }
  }

  void _updatePasswordError() {
    if (_passInteracted) {
      _validatePassword(passController.text);
    }
  }

  List<String> _validateAll() {
    final errors = <String>[];

    final emailValidation = _validateEmail(emailController.text.trim());
    if (emailValidation != null) errors.add(emailValidation);

    if (!_isPasswordValid)
      errors.add('La contraseña no cumple todos los requisitos');

    return errors;
  }

  // 2.1 Función de login modificada - animación DESPUÉS de la carga
  Future<void> _onLogin() async {
    if (_isLoading) return;

    // Activar carga inmediatamente
    setState(() {
      _isLoading = true;
      _emailInteracted = true;
      _passInteracted = true;
    });

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();

    // 2.2 Normalizar estado del oso inmediatamente
    isHandsUp?.change(false);
    isChecking?.change(false);
    numLook?.value = 50.0;

    // 2.3 Simular proceso de carga/verificación (2 segundos)
    await Future.delayed(const Duration(seconds: 2));

    // Validar después de la carga
    final finalErrors = _validateAll();
    setState(() {
      _emailError = _validateEmail(emailController.text.trim());
    });

    // 2.4 DESPUÉS de la carga, disparar las animaciones del oso
    if (finalErrors.isEmpty) {
      trigSuccess?.fire();
      // Esperar a que la animación de éxito se complete
      await Future.delayed(const Duration(milliseconds: 1500));
    } else {
      trigFail?.fire();
      // Esperar a que la animación de fallo se complete
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    emailController.addListener(_updateEmailError);
    passController.addListener(_updatePasswordError);

    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        setState(() {
          _emailInteracted = true;
        });
        _updateEmailError();
      }
    });

    passFocus.addListener(() {
      if (!passFocus.hasFocus) {
        setState(() {
          _passInteracted = true;
        });
        _updatePasswordError();
      }
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

                  if (value.isNotEmpty && !_emailInteracted) {
                    setState(() {
                      _emailInteracted = true;
                    });
                  }
                  _updateEmailError();
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  errorText: _emailError,
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

                  if (value.isNotEmpty && !_passInteracted) {
                    setState(() {
                      _passInteracted = true;
                    });
                  }
                  _updatePasswordError();
                },
                obscureText: _isObscure,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  // 1.5 Mostrar error general si se interactuó y no es válida
                  errorText: _passInteracted && !_isPasswordValid
                      ? 'La contraseña no cumple todos los requisitos'
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

              // 1.6 Checklist dinámico de contraseña - SIEMPRE mostrar cuando se interactúa
              if (_passInteracted) ...[
                const SizedBox(height: 10),
                Container(
                  width: size.width,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _passwordValidation.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              entry.value ? Icons.check_circle : Icons.cancel,
                              color: entry.value ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: entry.value ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

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

              // 3.1 Botón con spinner atractivo
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: _isLoading ? Colors.grey[700] : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: _isLoading ? null : _onLogin,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 3.2 Spinner colorido
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.yellow,
                              ),
                              backgroundColor: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "Verificando...",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
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