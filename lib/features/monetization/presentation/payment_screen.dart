import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';

/// Tip dialog — show with showDialog(context: ctx, builder: (_) => TipDialog(...))
class TipDialog extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverUsername;
  final String? livestreamId;

  const TipDialog({super.key, required this.receiverId, required this.receiverUsername, this.livestreamId});

  @override
  ConsumerState<TipDialog> createState() => _TipDialogState();
}

class _TipDialogState extends ConsumerState<TipDialog> {
  double _amount = 5.0;
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('💎', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('Send Tip to @${widget.receiverUsername}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(spacing: 10, children: [1.0, 5.0, 10.0, 50.0].map((a) {
            final sel = _amount == a;
            return GestureDetector(
              onTap: () => setState(() => _amount = a),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.primaryGradient : null,
                  color: sel ? null : AppColors.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? Colors.transparent : AppColors.darkBorder),
                ),
                child: Text('💎 \$${a.toInt()}', style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),
          TextField(
            controller: _msgCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add a message (optional)',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.darkCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: Material(color: Colors.transparent, child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _sending ? null : _send,
                child: Center(child: _sending
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Send \$${_amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
              )),
            ),
          ),
        ]),
      ),
    );
  }

  void _send() async {
    setState(() => _sending = true);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    try {
      await ref.read(monetizationRepositoryProvider).sendTip(
        senderId: user.uid, senderUsername: user.username, receiverId: widget.receiverId,
        amount: _amount, livestreamId: widget.livestreamId, message: _msgCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('💎 Sent \$${_amount.toStringAsFixed(0)} tip!'), backgroundColor: AppColors.success));
      }
    } catch (e) { setState(() => _sending = false); }
  }
}

/// Mock Stripe payment screen
class PaymentScreen extends StatefulWidget {
  final String creatorId;
  final String tier;
  final double price;
  const PaymentScreen({super.key, required this.creatorId, this.tier = 'pro', this.price = 4.99});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _card = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();
  bool _processing = false;

  @override
  void dispose() { _card.dispose(); _exp.dispose(); _cvv.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(backgroundColor: AppColors.darkBg, elevation: 0,
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder)),
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: (widget.tier == 'vip' ? AppColors.tierVip : AppColors.tierPro).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.star, color: widget.tier == 'vip' ? AppColors.tierVip : AppColors.tierPro)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${widget.tier.toUpperCase()} Subscription', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                Text('Monthly renewal', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ])),
              Text('\$${widget.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
            ]),
          ),
          const SizedBox(height: 28),
          const Text('Payment Method', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _field('Card Number', _card, 'XXXX XXXX XXXX XXXX', Icons.credit_card),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('Expiry', _exp, 'MM/YY', null)),
            const SizedBox(width: 14),
            Expanded(child: _field('CVV', _cvv, '***', Icons.lock)),
          ]),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 52, child: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Material(color: Colors.transparent, child: InkWell(
              borderRadius: BorderRadius.circular(14), onTap: _processing ? null : _pay,
              child: Center(child: _processing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Pay \$${widget.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
            )),
          )),
          const SizedBox(height: 16),
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('Powered by Stripe · Secured', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, IconData? icon) => TextField(
    controller: ctrl, style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label, labelStyle: TextStyle(color: AppColors.textMuted),
      hintText: hint, hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
      filled: true, fillColor: AppColors.darkCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textMuted, size: 20) : null,
    ),
  );

  void _pay() {
    setState(() => _processing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _processing = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Payment successful! Subscription activated.'), backgroundColor: AppColors.success));
      }
    });
  }
}
