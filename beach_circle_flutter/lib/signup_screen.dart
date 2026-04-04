import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'auth_screen.dart'; 

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  final _emailController = TextEditingController();
  final _passwordController1 = TextEditingController();
  final _passwordController2 = TextEditingController(); 

  bool _isLoading = false;

  String? selectedYear;
  String? selectedMajor;
  String? selectedInterest;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final majors = ['Computer Science', 'Biology', 'Business', 'Psychology'];
  final interests = ['Sports', 'Music', 'Art', 'Tech'];
  final years = ['Freshman', 'Sophomore', 'Junior', 'Senior', 'Alumni', 'NA'];

  //reuseable widget for the drop downs
  Widget inputBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  //widget for choosing major
  Widget majorField() {
    return inputBox(
      child: Autocomplete<String>(
        optionsBuilder: (textEditingValue) {
          return majors.where((m) =>
              m.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (value) => selectedMajor = value,
        fieldViewBuilder: (context, controller, focusNode, _) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: 'Major',
              border: InputBorder.none,
            ),
          );
        },
      ),
    );
  }

  //widget for choosing year
  Widget yearField() {
    return inputBox(
      child: DropdownButtonFormField<String>(
        initialValue: selectedYear,
        decoration: const InputDecoration(
          hintText: 'Year',
          border: InputBorder.none,
        ),
        items: years
            .map((y) => DropdownMenuItem(
                  value: y,
                  child: Text(y),
                ))
            .toList(),
        onChanged: (val) => setState(() => selectedYear = val),
      ),
    );
  }

  ////widget for choosing interests
  Widget interestField() {
    return inputBox(
      child: Autocomplete<String>(
        optionsBuilder: (textEditingValue) {
          return interests.where((i) =>
              i.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (value) => selectedInterest = value,
        fieldViewBuilder: (context, controller, focusNode, _) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: 'Interest',
              border: InputBorder.none,
            ),
          );
        },
      ),
    );
  }

  ///widget for choosing profile pic
  Widget profilePicField() {
  return inputBox(
    child: InkWell(
      onTap: _pickProfileImage, 
      child: SizedBox(
        height: 56, 
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade400,
              backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null 
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _profileImage == null
                    ? 'Upload Profile Picture'
                    : 'Change Profile Picture',
                style: TextStyle(
                  color: _profileImage == null
                      ? Colors.grey.shade700
                      : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.upload),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _pickProfileImage() async{
    final XFile? pickedProfile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedProfile != null) {
      setState(() {
        _profileImage = File(pickedProfile.path);
      });
    }
  }

  // --- UPDATED BACKEND LOGIC HERE ---
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password1 = _passwordController1.text.trim();
    final password2 = _passwordController2.text.trim();  
    
    bool isValidEmail(String email) {
      return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    }

    if (!isValidEmail(email)) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    if (password1 != password2) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Create User in Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password1,
      );

      final uid = userCredential.user!.uid;

      // 2. Prepare Data for Database
      // We align these keys with ProfileScreen expectations
      final data = {
        'name': email.split('@')[0], // Default name from email since we don't have a field
        'email': email,
        'major': selectedMajor ?? 'Undeclared',
        'year': selectedYear ?? 'Freshman',
        'interests': selectedInterest ?? '', // Changed key to 'interests' (plural) to match Profile
        'bio': '', // Default empty bio
        'created_at': FieldValue.serverTimestamp(),
      };

      // 3. Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign Up failed')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
      
      if (mounted) {
        // Pop back to login or dashboard
        Navigator.of(context).pop(); 
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(toolbarHeight: 20, backgroundColor: Colors.white, elevation: 0),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFEFCA08), 
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              const SizedBox(height: 40), 
              Container(
                width: screenWidth * 0.8, 
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child:
                      Text(
                      "Sign Up",
                      textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(height: 20),
                    //enter the email
                    Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                    const SizedBox(height: 20),
                    //enter the pass word
                    Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _passwordController1,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                    const SizedBox(height: 20),
                    //retype the pass word
                    Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _passwordController2,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Retype Password',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                    const SizedBox(height: 40),
                    //conatiner for major, year, interests, and profile pic
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columnWidth = (constraints.maxWidth - 12) / 2;

                        return Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: columnWidth,
                                  child: majorField(),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: columnWidth,
                                  child: yearField(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  width: columnWidth,
                                  child: interestField(),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: columnWidth,
                                  child: profilePicField(),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 50),
                    //signup button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    //nav back to login page
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}