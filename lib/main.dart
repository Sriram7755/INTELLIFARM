import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'dealer_home.dart';
import 'BrowseProductPage.dart';
import 'DealerOfferPage.dart';
import 'farmer_home.dart';
import 'product_upload_page.dart';
import 'farmer_profile_page.dart';
import 'crop_details_page.dart';
import 'crop_advisory_page.dart';
import 'marketplace_page.dart';
import 'dealer_profile_page.dart';
import 'chatbot.dart';
import 'rain_prediction.dart';
import 'employee_page.dart';
import 'customer_care_page.dart';
import 'my_products_page.dart';
import 'driver_home_page.dart';
import 'driver_list_page.dart';
import 'request_order_page.dart';
import 'order_detail_page.dart';
import 'EditProductPage.dart';
import 'ViewOffersPage.dart';
import 'MyOrderPage.dart';
import 'my_order_requests_page.dart';
import 'accepted_orders_page.dart';
import 'weather_page.dart';
import 'ProductDetailPage.Dart';
import 'NearbyShopsPage.dart';
import 'linknow.dart';
import 'dealer_Chat_list.dart';
import 'chat_page.dart';
import 'farmerchatlist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(IntelliFarmApp());
}

class IntelliFarmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntelliFarm',
      theme: ThemeData(
        primaryColor: Color(0xFF4CAF50),
        scaffoldBackgroundColor: Color(0xFFF1F8E9),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF388E3C),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4CAF50),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4CAF50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFFFFFFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/farmerHome': (context) => FarmerHome(),
        '/dealerHome': (context) => DealerHome(),
        '/upload': (context) => ProductUploadPage(),
        '/chatbot': (context) => ChatbotScreen(),
        '/farmer_profile': (context) => FarmerProfilePage(),
        '/dealerProfile': (context) => DealerProfilePage(),
        '/rainPrediction': (context) => RainPredictionScreen(),
        '/employeePage': (context) => EmployeePage(),
        '/customerCare': (context) => const CustomerCarePage(),
        '/myProducts': (context) => const MyProductsPage(),
        '/driverHome': (context) => DriverHomePage(),
        '/drivers': (context) => DriverListPage(),
        '/requestOrder': (context) => RequestOrderPage(),
        '/myOrderRequests': (context) => MyOrderRequestsPage(),
        '/acceptedOrders': (context) => const AcceptedOrdersPage(),
        '/marketplace': (context) => MarketplacePage(),
        '/browseProducts': (context) => BrowseProductsPage(),
        '/cropAdvisory': (context) => CropAdvisoryPage(),
        '/myOrders': (context) => MyOrdersPage(),
        '/productDetails': (context) => ProductDetailPage(),
        '/nearbyShops': (context) => const NearbyShopsPage(),
        '/linkSensor': (context) => const LinkSensorPage(),
        '/dealerChat': (context) => const DealerChatList(),
        '/chatPage': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return ChatPage(
    otherUserId: args['otherUserId'],
    otherUserName: args['otherUserName'],
    isFarmer: args['isFarmer'], // true if current user is farmer
  );
},
        '/farmerchatlist': (context) => const FarmerChatListPage(),

        '/weather': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return WeatherForecastPage(
            lat: args['lat'],
            lon: args['lon'],
            locationName: args['location'],
          );
        },
      },
    );
  }
}
