import 'package:flutter/material.dart';
import 'package:frontend/screens/company_profile.dart';

// Screens
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/offre_page.dart';
import 'package:frontend/screens/student_dashboard.dart';
import 'package:frontend/screens/admin_dashboard.dart';
import 'package:frontend/screens/company_dashboard.dart';
import 'package:frontend/screens/encadrant_dashboard.dart';
import 'package:frontend/screens/forgot_password_screen.dart';

import 'package:frontend/screens/journal_stage.dart';
import 'package:frontend/screens/upload_rapport.dart';
import 'package:frontend/screens/notification.dart';
import 'package:frontend/screens/profile.dart';

// Stage pages
import 'package:frontend/screens/stages_page.dart';
import 'package:frontend/screens/proposal_page.dart';
import 'package:frontend/screens/comments_page.dart';
import 'package:frontend/screens/my_requests_page.dart';

// Signup
import 'package:frontend/screens/signup/signup_choice.dart';
import 'package:frontend/screens/signup/signup_student.dart';
import 'package:frontend/screens/signup/signup_company.dart';
import 'package:frontend/screens/signup/signup_academic.dart';
import 'package:frontend/screens/signup/signup_professional.dart';

// Splash
import 'package:frontend/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Suivi de stage',

      // START APP HERE
initialRoute: '/splash',
      routes: {
        // SPLASH
'/splash': (context) => SplashScreen(),
        // AUTH
'/login': (context) => const LoginScreen(),
        '/signup_choice': (context) => const SignupChoice(),
        '/signup-student': (context) => const SignupStudent(),
        '/signup-company': (context) => const SignupCompany(),
        '/signup-academic': (context) => const SignupAcademic(),
        '/signup-professional': (context) => const SignupProfessional(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        // DASHBOARDS
        '/student-dashboard': (context) => const StudentDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/company-dashboard': (context) => const CompanyDashboard(),
        '/encadrant-dashboard': (context) => const EncadrantDashboard(),

        // STAGE FEATURES
        '/journal': (context) => const JournalStage(),
        '/upload-rapport': (context) => const UploadRapport(),
        '/stages': (context) => const StagesPage(),
        '/proposals': (context) => const ProposalPage(),
        '/comments': (context) => const CommentsPage(),
        '/my-requests': (context) => const MyRequestsPage(),

        // OTHER
        '/profile': (context) => const ProfilePage(),
        '/notifications': (context) => const NotificationsPage(),
'/company-profile': (context) =>  CompanyProfile(),
'/offre-page': (context) => const OffresPage(),      },
    );
  }
}