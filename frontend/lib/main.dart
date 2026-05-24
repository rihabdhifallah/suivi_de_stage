import 'package:flutter/material.dart';
import 'package:frontend/journal/journal_create_page.dart';
import 'package:frontend/journal/journal_difficultes_page.dart';
import 'package:frontend/journal/journal_list_page.dart';
import 'package:frontend/my_applications.dart';
import 'package:frontend/screens/add_company_page.dart';
import 'package:frontend/screens/apply-stage.dart';
import 'package:frontend/screens/create_tache_page.dart';
import 'package:frontend/screens/creer_reunion.dart';
import 'package:frontend/screens/demande_stage/demande_stage_page.dart';
import 'package:frontend/screens/encadrement_page.dart';
import 'package:frontend/screens/invitations.dart';
// Screens
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/presention.dart';
import 'package:frontend/screens/professionel_dashboard.dart';
import 'package:frontend/screens/rapports/create_rapport_page.dart';
import 'package:frontend/screens/rapports/rapport_detail_page.dart';
import 'package:frontend/screens/rapports/rapport_page.dart';
import 'package:frontend/screens/reunions.dart';
import 'package:frontend/screens/saved.dart';
import 'package:frontend/screens/stage-detail.dart';
import 'package:frontend/screens/student_dashboard.dart';
import 'package:frontend/screens/admin_dashboard.dart';
import 'package:frontend/screens/archived_actors_page.dart';
import 'package:frontend/screens/company_dashboard.dart';
import 'package:frontend/screens/encadrant_dashboard.dart';
import 'package:frontend/screens/forgot_password_screen.dart';

// Signup
import 'package:frontend/screens/signup/signup_choice.dart';
import 'package:frontend/screens/signup/signup_student.dart';
import 'package:frontend/screens/signup/signup_company.dart';
import 'package:frontend/screens/signup/signup_academic.dart';
import 'package:frontend/screens/signup/signup_professional.dart';

import 'package:frontend/screens/company_profile.dart';
import 'package:frontend/screens/offre_page.dart';
import 'package:frontend/screens/stagiaires_page.dart';
import 'package:frontend/screens/taches.dart';
import 'package:frontend/screens/upload_rapport.dart';
import 'package:frontend/screens/notification.dart';
import 'package:frontend/screens/profile.dart';

// Stage pages
import 'package:frontend/screens/stages_page.dart';
import 'package:frontend/screens/comments_page.dart';
import 'package:frontend/screens/my_requests_page.dart';

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
        '/admin-archives': (context) => const ArchivedActorsPage(),
        '/company-dashboard': (context) => const CompanyDashboard(),
  '/professional-dashboard': (context) => const ProfessionalDashboard(),
'/encadrant-dashboard': (context) => const EncadrantDashboard(),

        // STAGE FEATURES
        '/upload-rapport': (context) => const UploadRapport(),
        '/stages': (context) => const StagesPage(),
        '/comments': (context) => const CommentsPage(),
        '/my-requests': (context) => const MyRequestsPage(),

        // OTHER
        '/profile': (context) => const ProfilePage(),
        '/notifications': (context) => const NotificationsPage(),
        '/company-profile': (context) => const CompanyProfile(),
        '/offre-page': (context) => const OffresPage(),
        '/add-company-page': (context) => const AddCompanyPage(),
  '/my-applications': (c) => MyApplicationsPage(),
  '/stage-detail': (context) =>  StageDetail(),
    '/apply-stage': (context) =>  ApplyStagePage (),
    '/saved': (context) => SavedStagesPage(stages: []),
'/journal': (context) => JournalListPage(),
'/journal/create': (context) =>  JournalCreatePage(),
'/journal/difficultes': (context) =>  JournalDifficultesPage(),
'/rapports': (context) => const RapportPage(),
  '/rapports/create': (context) => const CreateRapportPage(),
      '/demande-stage': (context) =>const  DemandeStagePage(),
'/encadrement': (context) => const EncadrementPage(),
'/presentations': (context) => PresentationsPage(),
  '/creer_reunion': (context) => const CreerReunionPage(),
        '/reunions': (context) => const ReunionsPage(),
'/taches': (context) => const TachesPage(),
'/stagiaires': (context) => const StagiairesPage(),

'/taches/create': (context) => CreateTachePage(),
    '/invitations': (context) => const InvitationsPage(),


'/rapport-detail': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map;
  return RapportDetailPage(rapport: args);
},      },
    );
  }
}