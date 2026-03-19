import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import 'session_page.dart';
import 'shop_forms_page.dart';

/* The LicensesPage is a stateful widget that displays the licenses or terms of the application.
It includes a floating action button to toggle full-screen mode. */
class LicensesPage extends StatefulWidget {
  const LicensesPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  List<dynamic>? licenses;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  /* The _loadLicenses method is responsible for fetching the licenses associated
  with the authenticated user. It retrieves the authentication token from the TokenService
  and calls the AuthService's getLicenses method to fetch the licenses from the
  backend API. If the token is null, it logs a message indicating that the shop token
  is null. If the licenses are successfully fetched, it updates the state to store the
  licenses, which will trigger a rebuild of the UI to display them. This method is called
  during initialization to ensure that the licenses are loaded as soon as the page is displayed. */
  Future<void> _loadLicenses() async {
    final token = await TokenService.getToken(TokenType.shop);
    if (token != null) {
      final fetchedLicenses = await AuthService.getLicenses(token);
      setState(() {
        licenses = fetchedLicenses;
      });
    } else {
      print('Shop Token is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VOS LICENCES / COMMERCES'),
      ),
      body: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/tiliLogo.png',
              height: 150,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: licenses == null ? const Center(child: CircularProgressIndicator()) : licenses!.isEmpty ? const Center(child: Text('Aucune licence trouvée')) : ListView.builder(
              itemCount: licenses!.length,
              itemBuilder: (context, index) {
                final license = licenses![index];
                final store = license['store'] ?? {};
                String formattedExpiration = license['expiration'] ?? 'N/A';
                try {
                  final date = DateTime.parse(formattedExpiration);
                  formattedExpiration = DateFormat('dd/MM/yyyy').format(date);
                } catch (e) {
                  // Keep as is if parsing fails
                }
                return Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: GestureDetector(
                      onTap: () async {
                        final storeId = license['store']?['store_id']?.toString();
                        if (storeId != null) {
                          await TokenService.saveToken(TokenType.license, storeId);
                        }
                        final hasStore = store['name'] != null && store['name'].toString().isNotEmpty;
                        if (hasStore) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SessionPage(
                                license: license,
                                isFullScreen: widget.isFullScreen,
                                onToggleFullScreen: widget.onToggleFullScreen,
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ShopFormsPage(
                                license: license,
                                isFullScreen: widget.isFullScreen,
                                onToggleFullScreen: widget.onToggleFullScreen,
                              ),
                            ),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        color: (store['name'] != null && store['name'].toString().isNotEmpty) ? Colors.orange : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (store['name'] != null && store['name'].toString().isNotEmpty) ? store['name'] : 'ASSOCIER UN COMMERCE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: (store['name'] != null && store['name'].toString().isNotEmpty) ? null : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('ID Licence: ${license['licence_id'] ?? 'N/A'}'),
                              Text('Expiration: $formattedExpiration'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: IconButton(
        onPressed: widget.onToggleFullScreen,
        icon: Icon(
          widget.isFullScreen
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
        ),
      ),
    );
  }
}
