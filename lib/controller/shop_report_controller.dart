import '../models/shop_report_model.dart';
import 'home_controller.dart';

class ShopReportController {
  final HomeController _api = HomeController();


  void dispose() {
    _api.dispose();
  }
}
