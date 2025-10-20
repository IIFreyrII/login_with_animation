import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
// 3.1 Importar librería para Timer
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true; // Estado inicial

  // Cerebro de la lógica de las animaciones
  StateMachineController?
  controller; // El ? sirve para verificar que la variable no sea nulo
  // SMI: State Machine Input
  SMIBool? isChecking; // Activa la movilidad de los ojos
  SMIBool? isHandsUp; // Se tapa los ojos
  SMITrigger? trigSuccess; // Se emociona
  SMITrigger? trigFail; // Se pone triste

  // 2.1 Variable para el seguimiento de los ojos
  SMINumber? numLook; // Sigue el movimiento del cursor

  // 1.1) FocusNode (Nodo donde esta el foco)
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  // 3.2) Timer para detener la mirada al dejar de teclear
  Timer? _typingDebounce;

  // 4.1) Controllers: puede hacer algo con la información, la monitorea
  final emailController = TextEditingController();
  final passController = TextEditingController();

  // 4.2) Errores para mostrar en la UI
  String? emailError;
  String? passError;

  // 4.3) validadores
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // Mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return regex.hasMatch(pass);
  }

  // 4.4) Acción al botón
  void _onLogin() {
    // trim (recortar) sirve para eliminar espacios en un campo de texto
    final email = emailController.text.trim();
    final pass = passController.text;

    // Recalcular errores

    final eError = isValidEmail(email) ? null : 'Email no válido';
    final pError = isValidPassword(pass)
        ? null
        : 'Mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 caracter especial';

    // 4.5 Para avisar que hubo un cambio
    setState(() {
      emailError = eError;
      passError = pError;
    });

    // 4.6 Cerrar el teclado y bajar las manos
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    isChecking?.change(false);
    isHandsUp?.change(false);
    numLook?.value = 50.0; // Mirada neutral

    // 4.7 Activar triggers
    if (eError == null && pError == null) {
      trigSuccess?.fire();
    } else {
      trigFail?.fire();
    }
  }

  // 1.2) Listeners (Oyentes, escuchadores)
  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() {
      if (emailFocus.hasFocus) {
        // Manos abajo en email
        isHandsUp?.change(false); // Manos abajo en email
        // 2.2 Mirada neutral al enfocar el email
        numLook?.value = 50.0;
        isHandsUp?.change(false);
      }
    });
    passFocus.addListener(() {
      isHandsUp?.change(passFocus.hasFocus); // Manos arriba en password
    });
  }

  @override
  Widget build(BuildContext context) {
    // Para obtener el tamaño de la pantalla del disp.
    // MediaQuery = Consulta de las propiedades de la pantalla
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      // Evita nudge o cámaras frontales para móviles
      body: SafeArea(
        child: Padding(
          // Eje X/horizontal/derecha izquierda
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/animated_login_character.riv',
                  // Para vincular las animaciones con el estado de la maquina
                  stateMachines: ["Login Machine"],
                  // Al iniciarse
                  onInit: (artboard) {
                    controller = StateMachineController.fromArtboard(
                      artboard,
                      "Login Machine",
                    );
                    // Verificar que inició bien
                    if (controller == null) return;
                    artboard.addController(
                      controller!,
                    ); // El ! es para decirle que no es nulo
                    isChecking = controller!.findSMI('isChecking');
                    isHandsUp = controller!.findSMI('isHandsUp');
                    trigSuccess = controller!.findSMI('trigSuccess');
                    trigFail = controller!.findSMI('trigFail');
                    // 2.3 Enlazar variable con la animación
                    numLook = controller!.findSMI('numLook');
                  },
                ),
              ),
              // Espacio entre el oso y el texto Emial
              const SizedBox(height: 10),
              // Campo de texto del Email
              TextField(
                focusNode: emailFocus, // Asiganas el focusNode al TextField
                // 4.8) Enlazar el controller al TextField
                controller: emailController,
                onChanged: (value) {
                  // 2.4) Implementando numLook
                  // "Estoy escribiendo"
                  isChecking!.change(true);

                  // Ajuste de límites de 0 a 100
                  // 80 es una medidad de calibración
                  final look = (value.length / 100.0 * 100.0).clamp(0.0, 100.0);
                  numLook?.value = look;

                  // 3.3 Debounce: si vuelve a teclear, reinicia el contador
                  _typingDebounce
                      ?.cancel(); // Cancela cualquier Timer existente
                  _typingDebounce = Timer(
                    const Duration(milliseconds: 3000),
                    () {
                      if (!mounted) {
                        return;
                      }
                      // Mirada neutra
                      isChecking?.change(false);
                    },
                  );
                  // Si es nulo no intenta cargar la animación
                  if (isChecking == null) return;
                  // Activa el seguimiento de los ojos
                  isChecking!.change(true);
                },
                // Para que aparezca el @ en móviles UI/UX
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  // 4.9) Mostrar el texto del error
                  errorText: emailError,
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    // Esquinas redondeadas
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Campo de texto de la contraseña
              TextField(
                focusNode: passFocus, // Asiganas el focusNode al TextField
                // 4.8) Enlazar el controller al TextField
                controller: passController,
                onChanged: (value) {
                  if (isChecking != null) {
                    // Tapar los ojos al escribir el Email
                    // isChecking!.change(false);
                  }
                  // Si es nulo no intenta cargar la animación
                  if (isHandsUp == null) return;
                  // Activa el seguimiento de los ojos
                  isHandsUp!.change(true);
                },
                // Para ocultar el texto
                obscureText: _isObscure,
                // Para que aparezca el @ en móviles UI/UX
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  // 4.9) Mostrar el texto del error
                  errorText: passError,
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
                    // Esquinas redondeadas
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Texto "Olvidé contraseña"
              SizedBox(
                width: size.width,
                child: const Text(
                  "Forgot your password?",
                  // Alinear a la derecha
                  textAlign: TextAlign.right,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              // Botón de login
              const SizedBox(height: 10),
              // Botón estilo Android
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(12),
                ),
                // 4.10) Llamar a la función de login
                onPressed: _onLogin,
                child: Text("Login", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.black,
                          // En negritas
                          fontWeight: FontWeight.bold,
                          // Subrayado
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

  // 1.4) Liberación de recursos / limpieza de focos
  @override
  void dispose() {
    // 4.11) Limpieza de los controllers
    emailController.dispose();
    passController.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    _typingDebounce?.cancel(); // Cancela el Timer si está activo
    super.dispose();
  }
}