import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:room_rental_app/providers/auth_provider.dart';
import 'package:room_rental_app/providers/create_hostel_provider.dart';
import 'package:room_rental_app/providers/create_post_provider.dart';
import 'package:room_rental_app/providers/room_provider.dart';
import 'package:room_rental_app/providers/user_provider.dart';

import 'package:room_rental_app/screens/auth/login_screen.dart';
import 'package:room_rental_app/screens/auth/register_screen.dart';
import 'package:room_rental_app/screens/landlord/create_hostel_screen.dart';
import 'package:room_rental_app/screens/landlord/main_app_screen.dart';
import 'package:room_rental_app/screens/landlord/update_plan_screen.dart';
import 'package:room_rental_app/screens/user/main_app_screen.dart';
import 'package:room_rental_app/screens/user/room/create_post_screen.dart';
import 'package:room_rental_app/screens/welcome_screen.dart';
import 'package:room_rental_app/screens/landlord/favorite_list_screen.dart';
import 'package:room_rental_app/screens/landlord/change_password_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Intl.defaultLocale = 'vi_VN';

  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // User
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => CreatePostProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadCurrentUser()),

        // Landlord 
        ChangeNotifierProvider(create: (_) => CreateHostelProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Room Rental App',

        locale: const Locale('vi', 'VN'),
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        initialRoute: '/welcome',
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/main': (context) => const MainAppScreen(),
          '/create_post': (context) => const CreatePostScreen(),
          '/landlord_main': (context) => const LandlordMainAppScreen(),
          '/create_hostel': (context) => const CreateHostelScreen(),
          '/favorite-list': (context) => const FavoriteListScreen(),
          '/change_password': (context) => const ChangePasswordScreen(),
          '/upgrade_plan': (context) => const UpgradePlanScreen(),
        },
      ),
    );
  }
}
