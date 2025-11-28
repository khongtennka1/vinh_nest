import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:room_rental_app/screens/create_post_screen.dart';
import 'package:room_rental_app/screens/landlord/landlord_create_post_screen.dart';
import 'package:room_rental_app/screens/main_app_screen.dart';
import 'firebase_options.dart';

//Authentication and User Management
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

//Welcome Screen
import 'screens/welcome_screen.dart';

//User Data and Room Management
import 'providers/user_provider.dart';
import 'providers/room_provider.dart';
import 'providers/create_post_provider.dart';

//Landlord Data and Room Management
import 'providers/landlord/create_post_provider.dart';


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
        ChangeNotifierProvider(create: (_) => LandlordCreatePostProvider()),
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
          '/landlord_create_post': (context) => const LandlordCreatePostScreen(),
        },
      ),
    );
  }
}
