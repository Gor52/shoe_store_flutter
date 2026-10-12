import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';
import '../screens/home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/login_screen.dart'; 
import '../screens/register_screen.dart'; 
import '../screens/unauthorized_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/admin_orders_screen.dart';
import '../screens/manager_report_screen.dart';
import '../screens/shoe_form_screen.dart';
import '../screens/shoe_management_screen.dart';
import '../screens/stock_management_screen.dart';
import '../screens/brand_management_screen.dart';
import '../screens/category_management_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
   GoRoute(
      path: '/',
      builder: (context, state) {
        final search = state.uri.queryParameters['search'];
        final brand = state.uri.queryParameters['brand'];
        final sort = state.uri.queryParameters['sort'];
 
        final pageStr = state.uri.queryParameters['page'];
        final page = pageStr != null ? int.tryParse(pageStr) ?? 1 : 1;
        
        return HomeScreen(search: search, brand: brand, sort: sort, page: page);
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersScreen(),
    ),
    GoRoute(
      path: '/unauthorized',
      builder: (context, state) => const UnauthorizedScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
      redirect: (context, state) {
        final role = Provider.of<AuthNotifier>(context, listen: false).userRole;
        if (role != 'admin' && role != 'manager') {
          return '/unauthorized';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (context, state) => const AdminOrdersScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const UserManagementScreen(),
      redirect: (context, state) {
        final role = Provider.of<AuthNotifier>(context, listen: false).userRole;
        if (role != 'admin') return '/unauthorized'; 
        return null;
      },
    ),

    GoRoute(
      path: '/admin/shoes',
      builder: (context, state) => const ShoeManagementScreen(),
    ),
    GoRoute(
      path: '/admin/shoes/add',
      builder: (context, state) => const ShoeFormScreen(),
    ),
    GoRoute(
      path: '/admin/brands',
      builder: (context, state) => const BrandManagementScreen(),
      redirect: (context, state) {
        final role = Provider.of<AuthNotifier>(context, listen: false).userRole;
        if (role != 'admin') return '/unauthorized';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const CategoryManagementScreen(),
      redirect: (context, state) {
        final role = Provider.of<AuthNotifier>(context, listen: false).userRole;
        if (role != 'admin') return '/unauthorized';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/stocks',
      builder: (context, state) => const StockManagementScreen(),
    ),

    GoRoute(
      path: '/manager/report',
      builder: (context, state) => const ManagerReportScreen(),
      redirect: (context, state) {
        final role = Provider.of<AuthNotifier>(context, listen: false).userRole;
        if (role != 'manager') {
          return '/unauthorized'; 
        }
        return null;
      },
    ),
  ],
);