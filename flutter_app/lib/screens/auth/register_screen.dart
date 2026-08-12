import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/services/auth_manager.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/google_auth_service.dart';

import '../dashboard/dashboard_screen.dart';
import '../onboarding/profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool loading = false;

  // ===========================================================================
  // NORMAL REGISTRATION
  // ===========================================================================

  Future<void> register() async {
    final String name =
        nameController.text.trim();

    final String email =
        emailController.text.trim();

    final String phone =
        phoneController.text.trim();

    final String password =
        passwordController.text;

    // -------------------------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------------------------

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Please fill all fields'),
          backgroundColor:
              Colors.orange,
        ),
      );

      return;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a valid email address'),
          backgroundColor:
              Colors.orange,
        ),
      );

      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least 6 characters',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );

      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      // -----------------------------------------------------------------------
      // DEBUG
      // -----------------------------------------------------------------------

      print('');
      print('========================================');
      print('[REGISTER SCREEN] REGISTRATION START');
      print('========================================');

      print(
        '[REGISTER SCREEN] Name: $name',
      );

      print(
        '[REGISTER SCREEN] Email: $email',
      );

      print(
        '[REGISTER SCREEN] Phone: $phone',
      );

      // -----------------------------------------------------------------------
      // API REQUEST
      // -----------------------------------------------------------------------

      final result =
          await AuthService.register(
        name,
        email,
        phone,
        password,
      );

      if (!mounted) return;

      print(
        '[REGISTER SCREEN] API RESPONSE: '
        '$result',
      );

      // -----------------------------------------------------------------------
      // STOP LOADING
      // -----------------------------------------------------------------------

      setState(() {
        loading = false;
      });

      // -----------------------------------------------------------------------
      // FAILED
      // -----------------------------------------------------------------------

      if (result['success'] != true) {
        final String message =
            result['message']
                    ?.toString() ??
                'Registration failed';

        print(
          '[REGISTER SCREEN] REGISTRATION FAILED: '
          '$message',
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                Colors.redAccent,
            duration:
                const Duration(seconds: 5),
          ),
        );

        return;
      }

      // -----------------------------------------------------------------------
      // SUCCESS
      // -----------------------------------------------------------------------

      print(
        '[REGISTER SCREEN] Registration successful',
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful. Please login.',
          ),
          backgroundColor:
              Color(0xff29b6a6),
          duration:
              Duration(seconds: 3),
        ),
      );

      // Give SnackBar time to appear.
      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // GO TO LOGIN
      // -----------------------------------------------------------------------

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e, stackTrace) {
      print(
        '[REGISTER SCREEN] EXCEPTION: $e',
      );

      print(stackTrace);

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Registration error: $e'),
          backgroundColor:
              Colors.redAccent,
          duration:
              const Duration(seconds: 5),
        ),
      );
    }
  }

  // ===========================================================================
  // GOOGLE REGISTRATION / LOGIN
  // ===========================================================================

  Future<void> signInWithGoogle() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      print('');
      print('========================================');
      print('[REGISTER SCREEN] GOOGLE SIGN-IN');
      print('========================================');

      // -----------------------------------------------------------------------
      // GOOGLE ACCOUNT
      // -----------------------------------------------------------------------

      final googleUser =
          await GoogleAuthService.signIn();

      if (googleUser == null) {
        print(
          '[REGISTER SCREEN] Google sign-in cancelled',
        );

        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        return;
      }

      print(
        '[REGISTER SCREEN] Google account received',
      );

      print(
        '[REGISTER SCREEN] Email: '
        '${googleUser.email}',
      );

      print(
        '[REGISTER SCREEN] UID: '
        '${googleUser.uid}',
      );

      // -----------------------------------------------------------------------
      // BACKEND GOOGLE LOGIN
      // -----------------------------------------------------------------------

      final result =
          await AuthService.googleLogin(
        name:
            googleUser.displayName ??
                'User',
        email:
            googleUser.email ?? '',
        firebaseUid:
            googleUser.uid,
        photoUrl:
            googleUser.photoURL ?? '',
      );

      if (!mounted) return;

      print(
        '[REGISTER SCREEN] Google backend response: '
        '$result',
      );

      // -----------------------------------------------------------------------
      // API FAILURE
      // -----------------------------------------------------------------------

      if (result['success'] != true) {
        setState(() {
          loading = false;
        });

        final String message =
            result['message']
                    ?.toString() ??
                'Google sign-in failed';

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                Colors.redAccent,
            duration:
                const Duration(seconds: 5),
          ),
        );

        return;
      }

      // -----------------------------------------------------------------------
      // TOKEN
      // -----------------------------------------------------------------------

      final dynamic rawToken =
          result['token'];

      if (rawToken == null ||
          rawToken.toString().trim().isEmpty) {
        setState(() {
          loading = false;
        });

        print(
          '[REGISTER SCREEN] Google login succeeded '
          'but backend returned NO TOKEN',
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Google authentication succeeded, but the server did not return an authentication token.',
            ),
            backgroundColor:
                Colors.redAccent,
            duration:
                Duration(seconds: 6),
          ),
        );

        return;
      }

      final String token =
          rawToken.toString().trim();

      print(
        '[REGISTER SCREEN] Token received',
      );

      print(
        '[REGISTER SCREEN] Token length: '
        '${token.length}',
      );

      // -----------------------------------------------------------------------
      // USER DATA
      // -----------------------------------------------------------------------

      Map<String, dynamic> userData =
          {};

      final dynamic rawUser =
          result['user'];

      if (rawUser is Map) {
        userData =
            Map<String, dynamic>.from(
          rawUser,
        );
      }

      print(
        '[REGISTER SCREEN] User data: '
        '$userData',
      );

      // -----------------------------------------------------------------------
      // SAVE TOKEN
      // -----------------------------------------------------------------------

      await AuthManager()
          .saveToken(token);

      // -----------------------------------------------------------------------
      // SAVE USER
      // -----------------------------------------------------------------------

      await AuthManager()
          .saveUser(userData);

      print(
        '[REGISTER SCREEN] Token and user saved',
      );

      // -----------------------------------------------------------------------
      // VERIFY TOKEN
      // -----------------------------------------------------------------------

      final savedToken =
          await AuthManager().getToken();

      if (savedToken == null ||
          savedToken.trim().isEmpty) {
        setState(() {
          loading = false;
        });

        print(
          '[REGISTER SCREEN] CRITICAL: '
          'Saved token could not be verified',
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Google login succeeded, but your session could not be saved on this device.',
            ),
            backgroundColor:
                Colors.redAccent,
            duration:
                Duration(seconds: 5),
          ),
        );

        return;
      }

      print(
        '[REGISTER SCREEN] Token successfully '
        'saved and verified',
      );

      // -----------------------------------------------------------------------
      // PROFILE STATUS
      // -----------------------------------------------------------------------

      final bool profileCompleted =
          userData['profileCompleted'] ==
          true;

      print(
        '[REGISTER SCREEN] profileCompleted: '
        '$profileCompleted',
      );

      setState(() {
        loading = false;
      });

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // NAVIGATION
      // -----------------------------------------------------------------------

      if (!profileCompleted) {
        print(
          '[REGISTER SCREEN] → CompleteProfileScreen',
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CompleteProfileScreen(
              token: token,
            ),
          ),
          (route) => false,
        );
      } else {
        print(
          '[REGISTER SCREEN] → DashboardScreen',
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(
              token: token,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      print(
        '[REGISTER SCREEN] GOOGLE ERROR: $e',
      );

      print(stackTrace);

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Google sign-in error: $e'),
          backgroundColor:
              Colors.redAccent,
          duration:
              const Duration(seconds: 5),
        ),
      );
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMeshBackground(context),

          SafeArea(
            child: Column(
              children: [
                _buildHeaderBar(),

                Expanded(
                  child: Center(
                    child:
                        SingleChildScrollView(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child:
                          _buildGlassRegisterCard(
                        context,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BACKGROUND
  // ===========================================================================

  Widget _buildMeshBackground(
    BuildContext context,
  ) {
    final size =
        MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      color: const Color(0xffe2eafc),
      child: Stack(
        children: [
          // -------------------------------------------------------------------
          // AQUA
          // -------------------------------------------------------------------

          Positioned(
            top: -size.height * .2,
            left: -size.width * .1,
            child: Container(
              width:
                  size.width * .6,
              height:
                  size.height * .7,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                gradient:
                    RadialGradient(
                  colors: [
                    const Color(
                      0xff57ebd3,
                    ).withOpacity(.7),
                    const Color(
                      0xff7bf1a8,
                    ).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // ORANGE
          // -------------------------------------------------------------------

          Positioned(
            bottom:
                size.height * .1,
            left:
                -size.width * .2,
            child: Container(
              width:
                  size.width * .7,
              height:
                  size.height * .6,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                gradient:
                    RadialGradient(
                  colors: [
                    const Color(
                      0xffff7c54,
                    ).withOpacity(.65),
                    const Color(
                      0xffffbe7b,
                    ).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // PURPLE
          // -------------------------------------------------------------------

          Positioned(
            bottom:
                -size.height * .2,
            right:
                -size.width * .1,
            child: Container(
              width:
                  size.width * .7,
              height:
                  size.height * .8,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                gradient:
                    RadialGradient(
                  colors: [
                    const Color(
                      0xffb57eff,
                    ).withOpacity(.75),
                    const Color(
                      0xffded2f9,
                    ).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // GOLD
          // -------------------------------------------------------------------

          Positioned(
            top:
                size.height * .1,
            right:
                -size.width * .05,
            child: Container(
              width:
                  size.width * .45,
              height:
                  size.height * .5,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                gradient:
                    RadialGradient(
                  colors: [
                    const Color(
                      0xffffb26b,
                    ).withOpacity(.55),
                    const Color(
                      0xfffff4e0,
                    ).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeaderBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 24,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 20,
            ),
            onPressed:
                loading
                    ? null
                    : () =>
                        Navigator.maybePop(
                          context,
                        ),
          ),

          const SizedBox(
            width: 8,
          ),

          const Text(
            'Pulse AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REGISTER CARD
  // ===========================================================================

  Widget _buildGlassRegisterCard(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 40,
          sigmaY: 40,
        ),
        child: Container(
          width: 460,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 40,
          ),

          decoration:
              BoxDecoration(
            color:
                Colors.white.withOpacity(.45),

            borderRadius:
                BorderRadius.circular(32),

            border: Border.all(
              color:
                  Colors.white.withOpacity(.6),
              width: 1.5,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(.04),
                blurRadius: 40,
                offset:
                    const Offset(0, 20),
              ),
            ],
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // TITLE
              // ---------------------------------------------------------------

              const Text(
                'Create Account',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      Color(0xff1a1a1a),
                  letterSpacing:
                      -0.5,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Join Pulse AI to start monitoring your health intelligently.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w500,
                  color:
                      Colors.black.withOpacity(.6),
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              // ---------------------------------------------------------------
              // NAME
              // ---------------------------------------------------------------

              _buildInputField(
                controller:
                    nameController,
                label:
                    'Full Name',
                icon:
                    Icons
                        .person_outline_rounded,
              ),

              const SizedBox(
                height: 16,
              ),

              // ---------------------------------------------------------------
              // EMAIL
              // ---------------------------------------------------------------

              _buildInputField(
                controller:
                    emailController,
                label:
                    'Email Address',
                icon:
                    Icons
                        .mail_outline_rounded,
                keyboardType:
                    TextInputType
                        .emailAddress,
              ),

              const SizedBox(
                height: 16,
              ),

              // ---------------------------------------------------------------
              // PHONE
              // ---------------------------------------------------------------

              _buildInputField(
                controller:
                    phoneController,
                label:
                    'Phone Number',
                icon:
                    Icons
                        .phone_android_rounded,
                keyboardType:
                    TextInputType.phone,
              ),

              const SizedBox(
                height: 16,
              ),

              // ---------------------------------------------------------------
              // PASSWORD
              // ---------------------------------------------------------------

              _buildInputField(
                controller:
                    passwordController,
                label:
                    'Password',
                icon:
                    Icons
                        .lock_open_rounded,
                obscureText:
                    true,
              ),

              const SizedBox(
                height: 28,
              ),

              // ---------------------------------------------------------------
              // CREATE ACCOUNT
              // ---------------------------------------------------------------

              if (loading)
                const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xff9f6eff),
                    ),
                  ),
                )
              else
                Container(
                  height: 52,

                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius
                            .circular(
                      26,
                    ),

                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(
                          0xff29ebd4,
                        ),
                        Color(
                          0xff9f6eff,
                        ),
                      ],
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(
                          0xff9f6eff,
                        ).withOpacity(.2),
                        blurRadius: 12,
                        offset:
                            const Offset(
                          0,
                          6,
                        ),
                      ),
                    ],
                  ),

                  child:
                      ElevatedButton(
                    onPressed:
                        register,

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors.transparent,

                      shadowColor:
                          Colors.transparent,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          26,
                        ),
                      ),
                    ),

                    child:
                        const Text(
                      'Create Account',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            Colors.white,
                      ),
                    ),
                  ),
                ),

              const SizedBox(
                height: 20,
              ),

              // ---------------------------------------------------------------
              // DIVIDER
              // ---------------------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors
                          .black
                          .withOpacity(.1),
                      thickness: 1,
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                    ),
                    child: Text(
                      'OR',
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight
                                .bold,
                        color: Colors
                            .black
                            .withOpacity(
                          .4,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Divider(
                      color: Colors
                          .black
                          .withOpacity(.1),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              // ---------------------------------------------------------------
              // GOOGLE
              // ---------------------------------------------------------------

              SizedBox(
                height: 52,

                child:
                    OutlinedButton(
                  onPressed:
                      loading
                          ? null
                          : signInWithGoogle,

                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        const Color(
                      0xff333333,
                    ),

                    backgroundColor:
                        Colors.white
                            .withOpacity(
                      .2,
                    ),

                    side:
                        const BorderSide(
                      color:
                          Color(0xff29ebd4),
                      width: 1.5,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        26,
                      ),
                    ),
                  ),

                  child:
                      Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',

                        height: 20,

                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Icon(
                            Icons
                                .g_mobiledata,
                            size: 24,
                          );
                        },
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      const Text(
                        'Continue with Google',
                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              Color(
                            0xff2c3e50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // ---------------------------------------------------------------
              // LOGIN
              // ---------------------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    'Already have an account? ',
                    style:
                        TextStyle(
                      color: Colors
                          .black
                          .withOpacity(.5),
                      fontSize: 14,
                    ),
                  ),

                  GestureDetector(
                    onTap:
                        loading
                            ? null
                            : () {
                                Navigator
                                    .pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              },

                    child:
                        const Text(
                      'Login',
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xff9f6eff,
                        ),
                        fontWeight:
                            FontWeight
                                .bold,
                        fontSize: 14,
                        decoration:
                            TextDecoration
                                .underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // INPUT FIELD
  // ===========================================================================

  Widget _buildInputField({
    required TextEditingController
        controller,

    required String label,

    required IconData icon,

    bool obscureText =
        false,

    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextField(
      controller:
          controller,

      obscureText:
          obscureText,

      keyboardType:
          keyboardType,

      textInputAction:
          TextInputAction.next,

      style:
          const TextStyle(
        color:
            Colors.black87,
        fontSize:
            15,
      ),

      decoration:
          InputDecoration(
        prefixIcon:
            Icon(
          icon,
          color:
              Colors.black
                  .withOpacity(
            .4,
          ),
          size: 22,
        ),

        labelText:
            label,

        labelStyle:
            TextStyle(
          color:
              Colors.black
                  .withOpacity(
            .5,
          ),
          fontSize:
              14,
        ),

        floatingLabelStyle:
            const TextStyle(
          color:
              Color(
            0xff9f6eff,
          ),
          fontWeight:
              FontWeight
                  .bold,
        ),

        filled:
            true,

        fillColor:
            Colors.white
                .withOpacity(
          .35,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius
                  .circular(
            16,
          ),

          borderSide:
              BorderSide(
            color:
                Colors.white
                    .withOpacity(
              .5,
            ),
            width: 1,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius
                  .circular(
            16,
          ),

          borderSide:
              const BorderSide(
            color:
                Color(
              0xff9f6eff,
            ),
            width: 1.8,
          ),
        ),

        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }
}