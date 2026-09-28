import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PixaPulseApp());
}

class PixaPulseApp extends StatelessWidget {
  const PixaPulseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AudienceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AudienceScreen extends StatefulWidget {
  const AudienceScreen({Key? key}) : super(key: key);

  @override
  _AudienceScreenState createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  final _ble = FlutterReactiveBle();
  Color _backgroundColor = Colors.black;
  String _statusText = "بانتظار إشارة PixaPulse اللاسلكية...";
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _startBleScan();
  }

  void _startBleScan() {
    _ble.scanForDevices(withServices: []).listen((device) {
      // 1. التصفية بواسطة اسم جهاز البث المعتمد
      if (device.name == "BOOOMM") {
        final data = device.manufacturerData;
        
        // 2. التأكد من سلامة طول وحجم الحمولة (12 Bytes & Marker 0x01)
        if (data.length >= 12 && data[0] == 0x01 && data[1] == 0x0C) {
          int r = data[3];
          int g = data[4];
          int b = data[5];
          int torch = data[10];

          // 3. تحديث لون واجهة الموبايل فوراً
          setState(() {
            _backgroundColor = Color.fromRGBO(r, g, b, 1.0);
            _statusText = "متصل بالعرض التفاعلي!\nRGB: ($r, $g, $b)";
          });

          // 4. التحكم بفلاش الموبايل (Torch)
          if (torch > 0 && !_isTorchOn) {
            _isTorchOn = true;
            TorchLight.enableTorch().catchError((_) {});
          } else if (torch == 0 && _isTorchOn) {
            _isTorchOn = false;
            TorchLight.disableTorch().catchError((_) {});
          }

          // 5. اهتزاز لمسي بسيط إشعاراً بالتحديث
          Vibration.vibrate(duration: 80);
        }
      }
    }, onError: (error) {
      setState(() {
        _statusText = "خطأ في البحث البلوتوث: $error";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 22, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }
}
