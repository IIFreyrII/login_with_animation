import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

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

  // 1) FocusNode (Nodo donde esta el foco)
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  // 2) Listeners (Oyentes, escuchadores)
  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() {
      if (emailFocus.hasFocus) {
        isHandsUp?.change(false); // Manos abajo en email
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
                  },
                ),
              ),
              // Espacio entre el oso y el texto Emial
              const SizedBox(height: 10),
              // Campo de texto del Email
              TextField(
                focusNode: emailFocus, // Asiganas el focusNode al TextField
                onChanged: (value) {
                  if (isHandsUp != null) {
                    // No subir tapar los ojos al escribir el Email
                    // isHandsUp!.change(false);
                  }
                  // Si es nulo no intenta cargar la animación
                  if (isChecking == null) return;
                  // Activa el seguimiento de los ojos
                  isChecking!.change(true);
                },
                // Para que aparezca el @ en móviles UI/UX
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
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
                onPressed: () {},
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

  // 4) Liberación de recursos / limpieza de focos
  @override
  void dispose() {
    emailFocus.dispose();
    passFocus.dispose();
    super.dispose();
  }
}