import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../controllers/auth_controller.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

abstract class Routes {
  static const SPLASH = '/';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
}

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put<SplashController>(SplashController());
      }),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
  ];
}