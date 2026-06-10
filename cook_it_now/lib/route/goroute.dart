import 'package:go_router/go_router.dart';

import 'package:cook_it_now/screens/wellcome_screen.dart';
import 'package:cook_it_now/screens/wellcome_screen2.dart';
import 'package:cook_it_now/screens/signin.dart';
import 'package:cook_it_now/screens/loging.dart';
import 'package:cook_it_now/screens/home.dart';
import 'package:cook_it_now/screens/verification.dart';
import 'package:cook_it_now/screens/recipe_search.dart';
import 'package:cook_it_now/screens/history.dart';
import 'package:cook_it_now/screens/profile_user.dart';
import 'package:cook_it_now/screens/profileHealthpage.dart';
import 'package:cook_it_now/screens/terms&conditions.dart';

// forgot password screens
import 'package:cook_it_now/screens/forgot_password_email_page.dart';
import 'package:cook_it_now/screens/reset_password_verification.dart';
import 'package:cook_it_now/screens/update_password_page.dart';

// information pages
import 'package:cook_it_now/screens/informationpages/firstpage.dart';
import 'package:cook_it_now/screens/informationpages/secondpage.dart';
import 'package:cook_it_now/screens/informationpages/thirdpage.dart';
import 'package:cook_it_now/screens/informationpages/forthpage.dart';

import 'package:cook_it_now/screens/chatpage.dart';
import 'package:cook_it_now/screens/fulldetails.dart';
import 'package:cook_it_now/screens/recipe_chathistory.dart';
import 'package:cook_it_now/screens/saved_recipe_details.dart';

import '../models/chat_response_model.dart';

class MyAppRouter {
  late final GoRouter router;

  MyAppRouter() {
    router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const WelcomeScreen();
          },
        ),

        GoRoute(
          path: '/welScreen',
          builder: (context, state) {
            return const WelcomeStart();
          },
        ),

        GoRoute(
          path: '/signin',
          builder: (context, state) {
            return const SignIn();
          },
        ),

        GoRoute(
          path: '/loging',
          builder: (context, state) {
            return const Loging();
          },
        ),

        GoRoute(
          path: '/home',
          builder: (context, state) {
            return const Home();
          },
        ),

        // =========================
        // SIGNUP OTP VERIFICATION
        // =========================
        GoRoute(
          path: '/verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return VerificationScreen(email: extra["email"]);
          },
        ),

        // =========================
        // FORGOT PASSWORD FLOW
        // =========================
        GoRoute(
          path: '/forgot-password-email',
          builder: (context, state) {
            return const ForgotPasswordEmailPage();
          },
        ),

        GoRoute(
          path: '/reset-verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return ResetPasswordVerificationScreen(email: extra["email"]);
          },
        ),

        GoRoute(
          path: '/update-password',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return UpdatePasswordPage(email: extra["email"]);
          },
        ),

        GoRoute(
          path: '/recipepage',
          builder: (context, state) {
            return const RecipeSearch();
          },
        ),

        GoRoute(
          path: '/history',
          builder: (context, state) {
            return const History();
          },
        ),

        GoRoute(
          path: '/recipeChatHistory',
          builder: (context, state) {
            return const RecipeChatHistory();
          },
        ),

        GoRoute(
          path: '/savedRecipeDetails',
          builder: (context, state) {
            final recipe = state.extra as Map<String, dynamic>;
            return SavedRecipeDetailsPage(recipe: recipe);
          },
        ),

        GoRoute(
          path: '/recipeDetails',
          builder: (context, state) {
            final recipe = state.extra as RecipeItem;
            return RecipeDetailsPage(recipe: recipe);
          },
        ),

        GoRoute(
          path: '/userProfile',
          builder: (context, state) {
            return const ProfilePage();
          },
        ),

        GoRoute(
          path: '/healthProfile',
          builder: (context, state) {
            return const HealthPage();
          },
        ),

        GoRoute(
          path: '/terms',
          builder: (context, state) {
            return const TermsPage();
          },
        ),

        // =========================
        // INFORMATION PAGES
        // =========================
        GoRoute(
          path: '/firstpage',
          builder: (context, state) {
            return const FirstPage();
          },
        ),

        GoRoute(
          path: '/secondpage',
          builder: (context, state) {
            return const SecondPage();
          },
        ),

        GoRoute(
          path: '/thirdpage',
          builder: (context, state) {
            return const ThirdPage();
          },
        ),

        GoRoute(
          path: '/fourthpage',
          builder: (context, state) {
            return const FourthPage();
          },
        ),

        GoRoute(
          path: '/chatpage',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is String) {
              return ChatPage(initialMessage: extra);
            }

            if (extra is Map<String, dynamic>) {
              return ChatPage(
                initialMessage: (extra["initialMessage"] ?? "").toString(),
                sessionId: extra["sessionId"] as int?,
                existingMessages: extra["messages"] != null
                    ? List<Map<String, dynamic>>.from(
                        (extra["messages"] as List).map(
                          (e) => Map<String, dynamic>.from(e),
                        ),
                      )
                    : null,
              );
            }

            return const ChatPage(initialMessage: "");
          },
        ),
      ],
    );
  }
}
