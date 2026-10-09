import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../controllers/auth_controller.dart';
import '../screens/splash_screen.dart';
import '../screens/login_Screen.dart';
import '../screens/register_screen.dart';
import '../screens/home.dart';
import '../screens/fileUpload.dart';
import '../screens/transferUrl.dart';

abstract class Routes {
  static const SPLASH = '/';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const HOME = '/home';
  static const FILE_UPLOAD = '/file-upload';
  static const TRANSFER_URL = '/transfer-url';
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
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: Routes.FILE_UPLOAD,
      page: () => fileUpload(),
    ),
    GetPage(
      name: Routes.TRANSFER_URL,
      page: () => const transferUrl(),
    ),
  ];
}