import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'profile_page.dart';
import 'banking_page.dart';
import 'transport_page.dart';
import 'food_page.dart';
import 'qr_scan_page.dart';
import 'rewards_page.dart';
import 'history_page.dart';
import 'widgets/feature_card.dart';
import 'widgets/explore_icon.dart';
import 'balance_page.dart';
import 'recharge_page.dart';
import 'mobile_recharge_page.dart';
import 'wifi_recharge_page.dart';
import 'notification_center_page.dart';
import 'settings_page.dart';
import 'upi_pin_page.dart';
import 'tap_payment_page.dart';
import 'dth_recharge_page.dart';
import 'electricity_bill_page.dart';
import 'link_card_page.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String email;
  final String phone;
  final String password;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String upiPin;

  const HomeScreen({
    super.key,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.upiPin,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _cardUID;
  StreamSubscription<DatabaseEvent>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    _fetchCardUID();
  }

  void _fetchCardUID() async {
    final userRef = FirebaseDatabase.instance.ref('users/${widget.phone}/cardUID');
    final snapshot = await userRef.get();
    if (snapshot.exists) {
      setState(() {
        _cardUID = snapshot.value as String;
      });
      _listenForTaps();
    }
  }

  void _listenForTaps() {
    if (_cardUID == null) return;
    final tapRef = FirebaseDatabase.instance.ref('taps/$_cardUID');
    _tapSubscription = tapRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        // A tap event was created
        notificationService.showNotification(
          'Card Tapped!',
          'Your card was just used. Tap here to complete the payment.',
        );
        // We can also remove the event now to prevent re-triggering
        tapRef.remove();
      }
    });
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePageContent(
        username: widget.username,
        email: widget.email,
        phone: widget.phone,
        password: widget.password,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        upiPin: widget.upiPin,
        onPinSet: (pin) {},
        cardUID: _cardUID,
        onCardLinked: (uid) {
          setState(() {
            _cardUID = uid;
            _listenForTaps();
          });
        },
      ),
      QRScanPage(
        username: widget.username,
        email: widget.email,
        phone: widget.phone,
        password: widget.password,
        upiPin: widget.upiPin,
      ),
      RewardsPage(
        phone: widget.phone,
        username: widget.username,
        email: widget.email,
        password: widget.password,
      ),
      HistoryPage(
        phone: widget.phone,
        username: widget.username,
        email: widget.email,
        password: widget.password,
      ),
      ProfilePage(
        username: widget.username,
        email: widget.email,
        phone: widget.phone,
        password: widget.password,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('One Card One Nation', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications, size: 28),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10)), // TODO: Replace with unread count
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationCenterPage(
              phone: widget.phone,
              username: widget.username,
              email: widget.email,
              password: widget.password,
            )));
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(
                username: widget.username,
                email: widget.email,
                phone: widget.phone,
                password: widget.password,
              )));
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: const Icon(Icons.person, color: Colors.indigo),
              ),
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'QR'),
          BottomNavigationBarItem(icon: Icon(Icons.redeem), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  final String username;
  final String email;
  final String phone;
  final String password;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String upiPin;
  final Function(String) onPinSet;
  final String? cardUID;
  final Function(String) onCardLinked;

  const HomePageContent({
    super.key,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.upiPin,
    required this.onPinSet,
    required this.cardUID,
    required this.onCardLinked,
  });

  void navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                'Welcome $username 👋',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                'Explore your digital services',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),
              const Text(
                'Your Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    FeatureCard(
                      title: 'Identity',
                      icon: Icons.perm_identity,
                      onTap: () {
                        navigateTo(
                          context,
                          ProfilePage(
                            username: username,
                            password: password,
                            email: email,
                            phone: phone,
                          ),
                        );
                      },
                    ),
                    FeatureCard(
                      title: 'Banking',
                      icon: Icons.account_balance,
                      onTap: () {
                        navigateTo(context, const BankingPage());
                      },
                    ),
                    FeatureCard(
                      title: 'Transport',
                      icon: Icons.directions_bus,
                      onTap: () {
                        navigateTo(
                          context,
                          TransportPage(
                            username: username,
                            email: email,
                            phone: phone,
                            password: password,
                            upiPin: upiPin,
                            onPinSet: onPinSet,
                          ),
                        );
                      },
                    ),
                    FeatureCard(
                      title: 'Food',
                      icon: Icons.restaurant,
                      onTap: () {
                        navigateTo(
                            context,
                            FoodPage(
                              username: username,
                              email: email,
                              phone: phone,
                              password: password,
                              upiPin: upiPin,
                              onPinSet: onPinSet,
                            ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'Wallet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BalancePage(
                            phone: phone,
                            username: username,
                            email: email,
                            password: password,
                          ),
                        ),
                      );
                    },
                    child: const Text('Check Balance'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RechargePage(
                            phone: phone,
                            username: username,
                            email: email,
                            password: password,
                            upiPin: upiPin,
                            onPinSet: onPinSet,
                          ),
                        ),
                      );
                    },
                    child: const Text('Recharge'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MobileRechargePage(
                            phone: phone,
                            username: username,
                            email: email,
                            password: password,
                            upiPin: upiPin,
                            onPinSet: onPinSet,
                          ),
                        ),
                      );
                    },
                    child: const Text('Mobile Recharge'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WifiRechargePage(
                            phone: phone,
                            username: username,
                            email: email,
                            password: password,
                            upiPin: upiPin,
                            onPinSet: onPinSet,
                          ),
                        ),
                      );
                    },
                    child: const Text('WiFi Recharge'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DthRechargePage(
                            phone: phone,
                            username: username,
                            email: email,
                            password: password,
                            upiPin: upiPin,
                            onPinSet: onPinSet,
                          ),
                        ),
                      );
                    },
                    child: const Text('DTH Recharge'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ElectricityBillPage(
                            phone: phone,
                            username: username,
                            email: email,
                            password: password,
                            upiPin: upiPin,
                            onPinSet: onPinSet,
                          ),
                        ),
                      );
                    },
                    child: const Text('Electricity Bill'),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                icon: const Icon(Icons.tap_and_play),
                label: const Text('Tap to Pay'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TapPaymentPage(
                        upiPin: upiPin,
                        username: username,
                        email: email,
                        phone: phone,
                        password: password,
                        onPinSet: onPinSet,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 25),
              // TODO: Insert Recent Activity Widget here
              // TODO: Insert Analytics Chart here
              const Text(
                'Explore More',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ExploreIcon(icon: Icons.qr_code, label: 'Scan'),
                  ExploreIcon(icon: Icons.redeem, label: 'Rewards'),
                  ExploreIcon(icon: Icons.history, label: 'History'),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsPage(
                            phone: phone,
                            username: username,
                            email: email,
                            password: password,
                            isDarkMode: isDarkMode,
                            onThemeChanged: onThemeChanged,
                            upiPin: upiPin,
                            onPinSet: onPinSet,
                            cardUID: cardUID,
                            onCardLinked: onCardLinked,
                          ),
                        ),
                      );
                    },
                    child: ExploreIcon(icon: Icons.settings, label: 'Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



