import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/glass/glass.dart';
import '../domain/maintenance_ticket.dart';

class MaintenanceStatusPill extends StatelessWidget {
  const MaintenanceStatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'COMPLETED' => AppColors.auroraMint,
      'CANCELLED' || 'REJECTED' || 'CLOSED' => Colors.grey,
      'QUOTED' || 'RESCHEDULE_REQUESTED' => AppColors.auroraWarning,
      _ => AppColors.auroraAccent,
    };
    return GlassStatusPill(
      label: maintenanceStatusLabels[status] ?? status,
      color: color,
    );
  }
}
