import 'package:flutter/material.dart';

import '../../../core/domain/app_access_plan.dart';
import '../data/storekit_diagnostics.dart';

class StoreKitDiagnosticsScreen extends StatefulWidget {
  const StoreKitDiagnosticsScreen({
    required this.adoptedPlan,
    this.source,
    super.key,
  });

  final AppAccessPlan adoptedPlan;
  final StoreKitDiagnosticsSource? source;

  @override
  State<StoreKitDiagnosticsScreen> createState() =>
      _StoreKitDiagnosticsScreenState();
}

class _StoreKitDiagnosticsScreenState extends State<StoreKitDiagnosticsScreen> {
  late Future<StoreKitDiagnosticReport> _report = _load();

  Future<StoreKitDiagnosticReport> _load() =>
      (widget.source ?? StoreKitDiagnosticsSource()).load(widget.adoptedPlan);

  void _refresh() => setState(() => _report = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StoreKit diagnostics'),
        actions: [
          IconButton(
            key: const Key('refreshStoreKitDiagnostics'),
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<StoreKitDiagnosticReport>(
          future: _report,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final report = snapshot.requireData;
            return ListView(
              key: const Key('storeKitDiagnosticsReport'),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Read-only diagnostics. No account, receipt, transaction ID, or JWS data is shown.',
                ),
                const SizedBox(height: 16),
                _value('Storefront country', report.storefrontCountryCode),
                _value('App adopted plan', report.adoptedPlan.name),
                _value('Apple verified AdFree', _yesNo(report.appleHasAdFree)),
                _value('Apple verified Full', _yesNo(report.appleHasFull)),
                if (report.productError != null)
                  _value('Product query error', report.productError),
                if (report.nativeProductError != null)
                  _value(
                    'Native product query error',
                    report.nativeProductError,
                  ),
                if (report.nativeError != null)
                  _value('Native query error', report.nativeError),
                const Divider(height: 32),
                const Text(
                  'Flutter in_app_purchase products',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final product in report.products) ...[
                  const SizedBox(height: 10),
                  _value('Product ID', product.id),
                  _value('Display price', product.displayPrice),
                  _value('Raw price', product.rawPrice.toString()),
                  _value('Currency code', product.currencyCode),
                  _value('Currency symbol', product.currencySymbol),
                ],
                if (report.products.isEmpty) const Text('No products returned'),
                if (report.notFoundProductIds.isNotEmpty)
                  _value('Not found IDs', report.notFoundProductIds.join(', ')),
                const Divider(height: 32),
                const Text(
                  'Native StoreKit 2 products',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final product in report.nativeProducts) ...[
                  const SizedBox(height: 10),
                  _value('Native Product ID', product.id),
                  _value('Native display price', product.displayPrice),
                  _value('Native raw price', product.rawPrice.toString()),
                  _value('Native currency code', product.currencyCode),
                  _value('Native currency symbol', product.currencySymbol),
                ],
                if (report.nativeProducts.isEmpty)
                  const Text('No native StoreKit 2 products returned'),
                const Divider(height: 32),
                const Text(
                  'Current entitlements',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final entitlement in report.entitlements) ...[
                  const SizedBox(height: 10),
                  _value('Product ID', entitlement.productId),
                  _value('Verification', entitlement.verification),
                  _value('Product type', entitlement.productType),
                  _value(
                    'Expiration date present',
                    _yesNo(entitlement.hasExpirationDate),
                  ),
                  _value('Expired now', _yesNo(entitlement.isExpired)),
                  _value('Revoked', _yesNo(entitlement.isRevoked)),
                ],
                if (report.entitlements.isEmpty)
                  const Text('No target entitlements returned'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _value(String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: SelectableText('$label: ${value ?? 'Unavailable'}'),
  );

  String _yesNo(bool value) => value ? 'Yes' : 'No';
}
