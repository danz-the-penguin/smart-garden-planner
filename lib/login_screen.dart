import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'register_screen.dart';
import 'package:sgp/tree_list_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  // --- NEW: REGEX EMAIL VALIDATION METHOD ---
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  void _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    // --- NEW: ENFORCE REGEX FORMAT VALIDATION GATING PRIOR TO DB LOOKUP ---
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address structure."), 
          backgroundColor: Colors.orange
        ),
      );
      return; // Halt login execution
    }

    setState(() => _isLoading = true);
    
    // 1. Authenticate via DB
    final user = await DatabaseHelper.instance.loginUser(email, password);

    if (user != null) {
      // --- STATUS VALIDATION (Governance Enforcement) ---
      final String status = user['status'] ?? 'Active';

      if (status == 'Banned') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Access Denied: This account has been banned for violating community guidelines."), 
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isLoading = false);
        return; // Halt login
      }

      if (status == 'Suspended') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account Suspended: Please contact the Sabah Orchard Admin for verification."), 
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isLoading = false);
        return; // Halt login
      }

      // --- 2. POPULATE THE SESSION ---
      UserSession.currentUser = {
        'user_id': user['user_id'], 
        'name': user['name'],
        'role': user['role'],
        'status': status, // Sync status to session
      };

      if (mounted) {
        Widget destination = (user['role'] == 'Admin') 
          ? const AdminDashboardScreen() 
          : const TreeListScreen();

        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => destination)
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid email or password"), 
            backgroundColor: Colors.redAccent
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.park_rounded, size: 90, color: Colors.green),
              const SizedBox(height: 10),
              const Text(
                "Smart Garden Planner", 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)
              ),
              const Text("Mango Orchard Management & Commerce", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 50),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address", 
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.green), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password", 
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.green), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 25),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New to the orchard? "),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                    child: const Text(
                      "Create Account", 
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
