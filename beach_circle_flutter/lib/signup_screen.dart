import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'auth_screen.dart'; 

import 'email_config.dart'; 

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

  // --- EmailJS Logic ---
  Future<bool> _sendVerificationEmail(String email, String code) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost', 
          'Content-Type': 'application/json',
        },
        body: json.encode({
          // Reading keys safely from your email_config.dart file
          'service_id': EmailConfig.serviceId,
          'template_id': EmailConfig.templateId,
          'user_id': EmailConfig.publicKey,
          'template_params': {
            'to_email': email,
            'app_name': 'Beach Circle',
            'verification_code': code,
          }
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // THIS IS THE NEW LINE: It prints exactly WHY it failed!
        debugPrint('🛑 EMAILJS ERROR: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint("🛑 NETWORK ERROR: $e");
      return false;
    }
  }

  // --- The 6-Digit Code Dialog ---
  Future<void> _showVerificationDialog(String sentCode, String email, String password) async {
    final codeController = TextEditingController();
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // Force them to enter code or hit cancel
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Verify Your Email', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('We just sent a 6-digit code to $email. Please enter it below to verify your email and create your account.'),
                const SizedBox(height: 20),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '000000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isVerifying ? null : () async {
                  if (codeController.text.trim() == sentCode) {
                    setStateDialog(() => isVerifying = true);
                    
                    // Code matches! NOW we actually create the account.
                    await _finalizeUserCreation(email, password);
                    
                    if (mounted) {
                      Navigator.pop(context); // Close dialog
                      // Assuming AuthScreen handles routing to the main app once logged in
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect code. Please try again.'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: isVerifying 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Create Account'),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- Creates the actual Firebase Account ---
  Future<void> _finalizeUserCreation(String email, String password) async {
    try {
      // 1. Create User in Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Prepare Data for Database
      final data = {
        'name': email.split('@')[0], 
        'email': email,
        'major': selectedMajor ?? 'Undeclared',
        'year': selectedYear ?? 'Freshman',
        'interests': selectedInterest ?? '', 
        'bio': '', 
        'is_verified': true, // We know they are verified because they passed the check!
        'created_at': FieldValue.serverTimestamp(),
      };

      // 3. Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Created Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to create account: ${e.toString()}');
      }
    }
  }


  // --- UPDATED SUBMIT LOGIC ---
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

    // --- NEW CHECK: Does the account already exist? ---
    setState(() => _isLoading = true);
    try {
      // This will throw an error if the email is already in use
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        setState(() => _isLoading = false);
        _showErrorDialog('An account already exists for that email.');
        return;
      }
    } catch (e) {
       // Ignore fetch errors, let creation attempt handle it later
    }
    
    // 1. Generate a random 6 digit code
    String generatedCode = (Random().nextInt(900000) + 100000).toString();

    // 2. Send the email using EmailJS
    bool emailSent = await _sendVerificationEmail(email, generatedCode);

    setState(() => _isLoading = false);

    // 3. If email sent successfully, pop up the dialog to ask for the code
    if (emailSent) {
      if (mounted) {
        await _showVerificationDialog(generatedCode, email, password1);
      }
    } else {
      _showErrorDialog('Failed to send verification email. Please check your connection and try again.');
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

  Widget yearField() {
    return inputBox(
      child: DropdownButtonFormField<String>(
        initialValue: selectedYear,
        isExpanded: true, 
        decoration: const InputDecoration(
          hintText: 'Year',
          border: InputBorder.none,
        ),
        items: years
            .map((y) => DropdownMenuItem(
                  value: y,
                  child: Text(y, overflow: TextOverflow.ellipsis), 
                ))
            .toList(),
        onChanged: (val) => setState(() => selectedYear = val),
      ),
    );
  }

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

  Widget profilePicField() {
    return inputBox(
      child: InkWell(
        onTap: _pickProfileImage, 
        child: SizedBox(
          height: 56, 
          child: Row(
            children: [
              CircleAvatar(
                radius: 16, 
                backgroundColor: Colors.grey.shade400,
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null 
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _profileImage == null
                      ? 'Upload Pic'
                      : 'Change Pic',
                  style: TextStyle(
                    fontSize: 13, 
                    color: _profileImage == null
                        ? Colors.grey.shade700
                        : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis, 
                ),
              ),
              const Icon(Icons.upload, size: 20),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 20, 
        backgroundColor: Colors.white, 
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFEFCA08), 
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              
              const SizedBox(height: 10), 
              Container(
                width: screenWidth * 0.85, 
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), 
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Sign Up",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

                    const SizedBox(height: 30),
                    
                    Row(
                      children: [
                        Expanded(child: majorField()),
                        const SizedBox(width: 12),
                        Expanded(child: yearField()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: interestField()),
                        const SizedBox(width: 12),
                        Expanded(child: profilePicField()),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
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
                            : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    //nav back to login page
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
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
                          fontWeight: FontWeight.w600,
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