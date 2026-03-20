import 'package:get/get.dart';

/// Simple reactive flag toggled once init completes.
class LoadingController extends GetxController {
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  void setLoading(bool loading) {
    _isLoading.value = loading;
  }
}
