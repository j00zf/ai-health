import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../dashboard/dashboard_screen.dart';

class CompleteProfileScreen extends StatefulWidget {

  final String token;

  const CompleteProfileScreen({
    super.key,
    required this.token,
  });

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {

  final _formKey =
      GlobalKey<FormState>();

  final nicknameController =
      TextEditingController();

  final ageController =
      TextEditingController();

  final heightController =
      TextEditingController();

  final weightController =
      TextEditingController();

  String gender = "Male";

  String activityLevel =
      "Sedentary";

  String healthGoal =
      "Improve Fitness";

  bool isLoading = false;

  Future<void> saveProfile() async {

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final response =
          await http.post(
        Uri.parse(
          "http://localhost:5000/api/profile/create",
        ),
        headers: {
          "Content-Type":
              "application/json",
          "Authorization":
              "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "nickname":
              nicknameController.text,
          "age": int.parse(
              ageController.text),
          "gender": gender,
          "height": double.parse(
              heightController.text),
          "weight": double.parse(
              weightController.text),
          "activityLevel":
              activityLevel,
          "healthGoal":
              healthGoal,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode ==
          201) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(
              token:
                  widget.token,
            ),
          ),
        );

      } else {

        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          SnackBar(
            content: Text(
              data["message"],
            ),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(
              context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );

    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text(
          "Complete Profile",
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
                16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [

              TextFormField(
                controller:
                    nicknameController,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Nickname",
                ),
                validator: (v) =>
                    v!.isEmpty
                        ? "Required"
                        : null,
              ),

              const SizedBox(
                  height: 15),

              TextFormField(
                controller:
                    ageController,
                keyboardType:
                    TextInputType
                        .number,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Age",
                ),
                validator: (v) =>
                    v!.isEmpty
                        ? "Required"
                        : null,
              ),

              const SizedBox(
                  height: 15),

              DropdownButtonFormField(
                value: gender,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Gender",
                ),
                items: const [

                  DropdownMenuItem(
                    value: "Male",
                    child:
                        Text("Male"),
                  ),

                  DropdownMenuItem(
                    value:
                        "Female",
                    child: Text(
                        "Female"),
                  ),

                  DropdownMenuItem(
                    value: "Other",
                    child: Text(
                        "Other"),
                  ),
                ],
                onChanged: (value) {

                  setState(() {

                    gender =
                        value!;

                  });

                },
              ),

              const SizedBox(
                  height: 15),

              TextFormField(
                controller:
                    heightController,
                keyboardType:
                    TextInputType
                        .number,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Height (cm)",
                ),
              ),

              const SizedBox(
                  height: 15),

              TextFormField(
                controller:
                    weightController,
                keyboardType:
                    TextInputType
                        .number,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Weight (kg)",
                ),
              ),

              const SizedBox(
                  height: 15),

              DropdownButtonFormField(
                value:
                    activityLevel,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Activity Level",
                ),

                items: const [

                  DropdownMenuItem(
                    value:
                        "Sedentary",
                    child: Text(
                        "Sedentary"),
                  ),

                  DropdownMenuItem(
                    value: "Light",
                    child:
                        Text("Light"),
                  ),

                  DropdownMenuItem(
                    value:
                        "Moderate",
                    child: Text(
                        "Moderate"),
                  ),

                  DropdownMenuItem(
                    value:
                        "Active",
                    child:
                        Text("Active"),
                  ),

                  DropdownMenuItem(
                    value:
                        "Very Active",
                    child: Text(
                        "Very Active"),
                  ),
                ],

                onChanged: (value) {

                  setState(() {

                    activityLevel =
                        value!;

                  });

                },
              ),

              const SizedBox(
                  height: 15),

              DropdownButtonFormField(
                value: healthGoal,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Health Goal",
                ),

                items: const [

                  DropdownMenuItem(
                    value:
                        "Lose Weight",
                    child: Text(
                        "Lose Weight"),
                  ),

                  DropdownMenuItem(
                    value:
                        "Maintain Weight",
                    child: Text(
                        "Maintain Weight"),
                  ),

                  DropdownMenuItem(
                    value:
                        "Gain Weight",
                    child: Text(
                        "Gain Weight"),
                  ),

                  DropdownMenuItem(
                    value:
                        "Improve Fitness",
                    child: Text(
                        "Improve Fitness"),
                  ),

                  DropdownMenuItem(
                    value:
                        "Improve Sleep",
                    child: Text(
                        "Improve Sleep"),
                  ),
                ],

                onChanged: (value) {

                  setState(() {

                    healthGoal =
                        value!;

                  });

                },
              ),

              const SizedBox(
                  height: 25),

              SizedBox(
                width:
                    double.infinity,

                height: 55,

                child:
                    ElevatedButton(

                  onPressed:
                      isLoading
                          ? null
                          : saveProfile,

                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Complete Profile",
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}