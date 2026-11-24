import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/product_form_controller.dart';

class ProductLookSection extends StatelessWidget {
  const ProductLookSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<ProductFormController>(
      id: ProductFormController.lookId,
      builder: (controller) {
        final images = controller.imageUrls;
        return AppCard(
          title: 'تسوق الإطلالة (Shop the Look)',
          trailing: AppButton(
            label: controller.lookEnabled ? 'تعطيل' : 'تفعيل',
            variant: AppButtonVariant.ghost,
            icon: AppIcons.pin,
            onPressed: controller.toggleLook,
          ),
          child: !controller.lookEnabled
              ? Text(
                  'فعّل الإطلالة لإضافة نقاط تفاعلية على صورة الموديل وربط قطع أخرى.',
                  style: AppTextStyles.body2.copyWith(color: c.textSecondary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (images.isEmpty)
                      Text('أضف صوراً أولاً ثم ضع النقاط عليها.', style: AppTextStyles.body2.copyWith(color: c.warning))
                    else ...[
                      AppDropdown<int>(
                        label: 'الصورة المستخدمة للإطلالة',
                        value: controller.lookImageIndex.clamp(0, images.length - 1),
                        items: [
                          for (var i = 0; i < images.length; i++) AppDropdownItem(i, 'صورة ${i + 1}'),
                        ],
                        onChanged: (v) {
                          if (v != null) controller.setLookImageIndex(v);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('انقر على الصورة لإضافة نقطة', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      AspectRatio(
                        aspectRatio: 0.8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return GestureDetector(
                                onTapDown: (details) {
                                  final x = details.localPosition.dx / constraints.maxWidth;
                                  final y = details.localPosition.dy / constraints.maxHeight;
                                  controller.addLookPin(x.clamp(0, 1), y.clamp(0, 1));
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppNetworkImage(
                                      url: images[controller.lookImageIndex.clamp(0, images.length - 1)],
                                      width: constraints.maxWidth,
                                      height: constraints.maxHeight,
                                      radius: 0,
                                    ),
                                    ...controller.lookPins.map((pin) {
                                      return Positioned(
                                        left: pin.x * constraints.maxWidth - 12,
                                        top: pin.y * constraints.maxHeight - 12,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: c.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: c.onPrimary, width: 2),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${controller.lookPins.indexOf(pin) + 1}',
                                            style: AppTextStyles.caption.copyWith(color: c.onPrimary, fontSize: 10),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(controller.lookPins.length, (i) {
                      final pin = controller.lookPins[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: c.primary,
                              child: Text('${i + 1}', style: AppTextStyles.caption.copyWith(color: c.onPrimary)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: AppDropdown<String>(
                                label: 'المنتج المرتبط',
                                value: pin.productId.isEmpty ? null : pin.productId,
                                hint: 'اختر منتجاً',
                                items: controller.productOptions
                                    .map((p) => AppDropdownItem(p.productId, '${p.displayName} (${p.productId})'))
                                    .toList(),
                                onChanged: (v) => controller.setLookPinProduct(i, v ?? ''),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: AppTextField(label: 'الدور EN', controller: pin.role)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: AppTextField(label: 'الدور AR', controller: pin.roleAr)),
                            IconButton(
                              onPressed: () => controller.removeLookPin(i),
                              icon: Icon(AppIcons.delete, color: c.error, size: AppIconSize.md),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }
}
