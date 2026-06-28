import 'package:flutter/material.dart';
import 'database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  String _selectedRole = 'Customer'; 

  // --- HANDLES ACCOUNT CONFLICT REGISTRATION GOVERNANCE ---
  void _handleRegister() async {
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields."))
      );
      return;
    }

    // Call the updated validation query handler
    int resultId = await DatabaseHelper.instance.registerUser(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passController.text,
      _selectedRole,
    );

    if (resultId == -1) {
      // UNIQUE CONSTRAINT COLLISION: Trigger clear warning alert
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text("Registration Error"),
              ],
            ),
            content: const Text(
              "This email is already registered. Only one email account is allowed for one user role.",
              style: TextStyle(height: 1.3),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
      return; // Halt operational assignment sequence execution
    }

    // SUCCESSFUL REGISTRATION PATH
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully! Log in now."),
          backgroundColor: Colors.green,
        )
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register"), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(
              controller: _nameController, 
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController, 
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController, 
              decoration: const InputDecoration(labelText: "Password"), 
              obscureText: true,
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              items: ['Farmer', 'Customer'].map((r) => DropdownMenuItem(value: r, child: Text("Join as $r"))).toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _handleRegister, child: const Text("Create Account")),
          ],
        ),
      ),
    );
  }
}
