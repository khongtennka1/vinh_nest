import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:room_rental_app/providers/create_hostel_provider.dart';
import 'package:room_rental_app/providers/create_post_provider.dart';
import 'package:room_rental_app/screens/auth/login_screen.dart';
import 'package:room_rental_app/screens/auth/register_screen.dart';
import 'package:room_rental_app/screens/landlord/create_hostel_screen.dart';
import 'package:room_rental_app/screens/landlord/main_app_screen.dart';
import 'package:room_rental_app/screens/user/main_app_screen.dart';
import 'package:room_rental_app/screens/user/room/create_post_screen.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';
import 'providers/user_provider.dart';
import 'providers/room_provider.dart';
// import 'providers/landlord_create_post_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        //Auth
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        //User
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => CreatePostProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadCurrentUser()),
        //Landlord
        // ChangeNotifierProvider(create: (_) => LandlordCreatePostProvider()),
        ChangeNotifierProvider(create: (_) => CreateHostelProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Room Rental App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        initialRoute: '/welcome',
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/main': (context) => const MainAppScreen(),
          '/create_post': (context) => const CreatePostScreen(),
          '/landlord_main': (context) => const LandlordMainAppScreen(),
          '/create_hostel': (context) => const CreateHostelScreen()
        },
      ),
    );
  }
}
