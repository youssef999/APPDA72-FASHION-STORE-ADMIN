import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../models/coupon_model.dart';

class InfluencerReportDialog extends StatefulWidget {
  final CouponModel coupon;

  const InfluencerReportDialog({super.key, required this.coupon});

  @override
  State<InfluencerReportDialog> createState() => _InfluencerReportDialogState();
}

class _InfluencerReportDialogState extends State<InfluencerReportDialog> {
  bool _loading = true;
  String? _error;
  int uniqueUsers = 0;
  int ordersCount = 0;
  num netSales = 0;
  int approxInstalls = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coupon = widget.coupon;
      uniqueUsers = coupon.usedBy.length;

      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('couponCode', isEqualTo: coupon.code)
          .get();

      ordersCount = 0;
      netSales = 0;
      final orderUids = <String>{};
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final status = '${data['status'] ?? ''}'.toLowerCase();
        if (status == 'rejected' || status == 'cancelled' || status == 'canceled') continue;
        ordersCount++;
        final finalTotal = data['finalTotal'];
        if (finalTotal is num) {
          netSales += finalTotal;
        } else {
          final total = Formatters.toNum(data['total']);
          final discount = Formatters.toNum(data['discount']);
          netSales += total - discount;
        }
        final uid = '${data['user_uid'] ?? data['uid'] ?? data['userId'] ?? ''}';
        if (uid.isNotEmpty) orderUids.add(uid);
      }

      final windowDays = coupon.attributionWindowDays;
      var installs = 0;
      for (final uid in {...coupon.usedBy, ...orderUids}) {
        final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
        if (!userDoc.exists) continue;
        final createdAt = Formatters.toDate(userDoc.data()?['createdAt']);
        if (createdAt == null) continue;
        // Approximate "install": account created within attribution window before first coupon use.
        // Without per-user first-use timestamp, use coupon createdAt / expires as soft bounds.
        final anchor = coupon.createdAt ?? coupon.expiresAt.subtract(Duration(days: windowDays));
        final diff = anchor.difference(createdAt).inDays.abs();
        if (diff <= windowDays) installs++;
      }
      approxInstalls = installs;

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final coupon = widget.coupon;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تقرير حملة ${coupon.influencerDisplay.isEmpty ? coupon.code : coupon.influencerDisplay}',
                  style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text('كود ${coupon.code} · نافذة ${coupon.attributionWindowDays} يوم',
                  style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(_error!, style: AppTextStyles.body2.copyWith(color: c.error))
              else ...[
                _Metric(label: 'مستخدمون فريدون (usedBy)', value: '$uniqueUsers'),
                _Metric(label: 'طلبات بالكود', value: '$ordersCount'),
                _Metric(label: 'صافي المبيعات', value: Formatters.money(netSales)),
                _Metric(label: 'تحميلات تقريبية', value: '$approxInstalls'),
              ],
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppButton(label: 'إغلاق', variant: AppButtonVariant.outlined, onPressed: () => Navigator.of(context).pop()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body2.copyWith(color: c.textSecondary))),
          Text(value, style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
        ],
      ),
    );
  }
}
