import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/services/auth_manager.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/google_auth_service.dart';

import '../dashboard/dashboard_screen.dart';
import '../onboarding&account/profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<void> login() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text;

    if (email.isEmpty ||
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

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      print('');
      print('========================================');
      print('[LOGIN SCREEN] LOGIN START');
      print('[LOGIN SCREEN] Email: $email');
      print('========================================');

      final result =
          await AuthService.login(
        email,
        password,
      );

      if (!mounted) return;

      print(
        '[LOGIN SCREEN] API result: $result',
      );

      final bool success =
          result['success'] == true;

      // -----------------------------------------------------------------------
      // FAILED LOGIN
      // -----------------------------------------------------------------------

      if (!success) {
        setState(() {
          loading = false;
        });

        final message =
            result['message']
                    ?.toString() ??
                'Login failed';

        print(
          '[LOGIN SCREEN] LOGIN FAILED: '
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
          '[LOGIN SCREEN] SERVER RETURNED '
          'SUCCESS WITHOUT TOKEN',
        );

        print(
          '[LOGIN SCREEN] Response: $result',
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Login succeeded, but the server did not return an authentication token.',
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
        '[LOGIN SCREEN] Token received',
      );

      print(
        '[LOGIN SCREEN] Token length: '
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
        '[LOGIN SCREEN] User data: '
        '$userData',
      );

      // -----------------------------------------------------------------------
      // SAVE TOKEN
      // -----------------------------------------------------------------------

      try {
        await AuthManager()
            .saveToken(token);

        await AuthManager()
            .saveUser(userData);
      } catch (e) {
        setState(() {
          loading = false;
        });

        print(
          '[LOGIN SCREEN] TOKEN SAVE ERROR: '
          '$e',
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Login succeeded, but the session could not be saved on this device.',
            ),
            backgroundColor:
                Colors.redAccent,
          ),
        );

        return;
      }

      // -----------------------------------------------------------------------
      // VERIFY STORAGE
      // -----------------------------------------------------------------------

      final savedToken =
          await AuthManager().getToken();

      if (savedToken == null ||
          savedToken.isEmpty) {
        setState(() {
          loading = false;
        });

        print(
          '[LOGIN SCREEN] CRITICAL: '
          'TOKEN VERIFICATION FAILED',
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save your login session.',
            ),
            backgroundColor:
                Colors.redAccent,
          ),
        );

        return;
      }

      print(
        '[LOGIN SCREEN] Token successfully '
        'saved and verified',
      );

      // -----------------------------------------------------------------------
      // STOP LOADING
      // -----------------------------------------------------------------------

      setState(() {
        loading = false;
      });

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // PROFILE STATUS
      // -----------------------------------------------------------------------

      final bool profileCompleted =
          userData['profileCompleted'] ==
          true;

      print(
        '[LOGIN SCREEN] profileCompleted: '
        '$profileCompleted',
      );

      // -----------------------------------------------------------------------
      // NAVIGATION
      // -----------------------------------------------------------------------

      if (!profileCompleted) {
        print(
          '[LOGIN SCREEN] → CompleteProfileScreen',
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
          '[LOGIN SCREEN] → DashboardScreen',
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
        '[LOGIN SCREEN] EXCEPTION: $e',
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
              Text('Login error: $e'),
          backgroundColor:
              Colors.redAccent,
          duration:
              const Duration(seconds: 5),
        ),
      );
    }
  }

  // ===========================================================================
  // GOOGLE LOGIN
  // ===========================================================================

  Future<void> signInWithGoogle() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      print(
        '[LOGIN SCREEN] Starting Google login',
      );

      final googleUser =
          await GoogleAuthService.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        return;
      }

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
        '[LOGIN SCREEN] Google API result: '
        '$result',
      );

      if (result['success'] != true) {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              result['message']
                      ?.toString() ??
                  'Google login failed',
            ),
            backgroundColor:
                Colors.redAccent,
          ),
        );

        return;
      }

      final dynamic rawToken =
          result['token'];

      if (rawToken == null ||
          rawToken.toString().trim().isEmpty) {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Google login succeeded, but no authentication token was returned.',
            ),
            backgroundColor:
                Colors.redAccent,
          ),
        );

        return;
      }

      final String token =
          rawToken.toString().trim();

      Map<String, dynamic> userData =
          {};

      if (result['user'] is Map) {
        userData =
            Map<String, dynamic>.from(
          result['user'],
        );
      }

      // Save BOTH token and user.
      await AuthManager()
          .saveToken(token);

      await AuthManager()
          .saveUser(userData);

      final savedToken =
          await AuthManager().getToken();

      if (savedToken == null ||
          savedToken.isEmpty) {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Google login succeeded, but the session could not be saved.',
            ),
            backgroundColor:
                Colors.redAccent,
          ),
        );

        return;
      }

      setState(() {
        loading = false;
      });

      if (!mounted) return;

      final profileCompleted =
          userData['profileCompleted'] ==
          true;

      if (!profileCompleted) {
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Google login error: $e'),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    emailController.dispose();
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
                        vertical: 40,
                      ),
                      child:
                          _buildGlassLoginCard(
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
          Positioned(
            top: -size.height * .2,
            left: -size.width * .1,
            child: Container(
              width: size.width * .6,
              height: size.height * .7,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
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
          Positioned(
            bottom: size.height * .1,
            left: -size.width * .2,
            child: Container(
              width: size.width * .7,
              height: size.height * .6,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
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
          Positioned(
            bottom: -size.height * .2,
            right: -size.width * .1,
            child: Container(
              width: size.width * .7,
              height: size.height * .8,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
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
          Positioned(
            top: size.height * .1,
            right: -size.width * .05,
            child: Container(
              width: size.width * .45,
              height: size.height * .5,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
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
            onPressed: () =>
                Navigator.maybePop(
              context,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Pulse AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOGIN CARD
  // ===========================================================================

  Widget _buildGlassLoginCard(
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
          width: 440,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 44,
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
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome Back',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      Color(0xff1a1a1a),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Sign in to access your dashboard',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w500,
                  color:
                      Colors.black.withOpacity(.6),
                ),
              ),

              const SizedBox(
                height: 36,
              ),

              _buildInputField(
                controller:
                    emailController,
                label:
                    'Email Address',
                icon:
                    Icons.mail_outline_rounded,
                keyboardType:
                    TextInputType.emailAddress,
              ),

              const SizedBox(
                height: 20,
              ),

              _buildInputField(
                controller:
                    passwordController,
                label:
                    'Password',
                icon:
                    Icons.lock_open_rounded,
                obscureText:
                    true,
              ),

              const SizedBox(
                height: 30,
              ),

              loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Color(0xff9f6eff),
                      ),
                    )
                  : SizedBox(
                      height: 52,
                      child:
                          DecoratedBox(
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
                        ),
                        child:
                            ElevatedButton(
                          onPressed:
                              login,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors
                                    .transparent,
                            shadowColor:
                                Colors
                                    .transparent,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                26,
                              ),
                            ),
                          ),
                          child:
                              const Text(
                            'Login',
                            style:
                                TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

              const SizedBox(
                height: 24,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        Divider(
                      color: Colors
                          .black
                          .withOpacity(.1),
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child:
                        Text(
                      'OR',
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        Divider(
                      color: Colors
                          .black
                          .withOpacity(.1),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                height: 52,
                child:
                    OutlinedButton(
                  onPressed:
                      loading
                          ? null
                          : signInWithGoogle,
                  style:
                      OutlinedButton.styleFrom(
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
                      const Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Icon(
                        Icons
                            .account_circle_outlined,
                        size: 22,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Text(
                        'Continue with Google',
                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style:
                        TextStyle(
                      color: Colors
                          .black
                          .withOpacity(.5),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: loading
                        ? null
                        : () =>
                            Navigator.pushNamed(
                              context,
                              '/register',
                            ),
                    child:
                        const Text(
                      'Create Account',
                      style:
                          TextStyle(
                        color:
                            Color(0xff9f6eff),
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
  // INPUT
  // ===========================================================================

  Widget _buildInputField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
      ),
      decoration:
          InputDecoration(
        prefixIcon: Icon(
          icon,
          color:
              Colors.black.withOpacity(.4),
          size: 22,
        ),
        labelText: label,
        labelStyle: TextStyle(
          color:
              Colors.black.withOpacity(.5),
          fontSize: 14,
        ),
        floatingLabelStyle:
            const TextStyle(
          color:
              Color(0xff9f6eff),
          fontWeight:
              FontWeight.bold,
        ),
        filled: true,
        fillColor:
            Colors.white.withOpacity(.35),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              BorderSide(
            color:
                Colors.white.withOpacity(.5),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color:
                Color(0xff9f6eff),
            width: 1.8,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }
}