// lib/presentation/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ─── Cricket A7 App Bar ──────────────────────────────────────────────────────

class A7AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;

  const A7AppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgCard,
      elevation: 0,
      leading: leading,
      title: Row(
        children: [
          if (showLogo) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('A7',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    )),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(title,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              )),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

// ─── Cricket A7 Card ─────────────────────────────────────────────────────────

class A7Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;

  const A7Card({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: hasBorder
              ? Border.all(color: AppColors.border, width: 1)
              : null,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ─── Live Badge ───────────────────────────────────────────────────────────────

class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.live.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.live, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.live,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text('LIVE',
                  style: TextStyle(
                    color: AppColors.live,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Score Display Widget ─────────────────────────────────────────────────────

class ScoreDisplay extends StatelessWidget {
  final String teamName;
  final String score;
  final String overs;
  final bool isCurrentTeam;

  const ScoreDisplay({
    super.key,
    required this.teamName,
    required this.score,
    required this.overs,
    required this.isCurrentTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamName,
            style: TextStyle(
              fontSize: 13,
              color: isCurrentTeam
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 4),
        Text(score,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isCurrentTeam ? AppColors.primary : AppColors.textSecondary,
              height: 1,
            )),
        Text('($overs Ov)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            )),
      ],
    );
  }
}

// ─── Run Rate Bar ─────────────────────────────────────────────────────────────

class RunRateBar extends StatelessWidget {
  final double crr;
  final double? rrr;

  const RunRateBar({super.key, required this.crr, this.rrr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RateChip(label: 'CRR', value: crr.toStringAsFixed(2),
            color: AppColors.primary),
        if (rrr != null) ...[
          const SizedBox(width: 8),
          _RateChip(label: 'RRR', value: rrr!.toStringAsFixed(2),
              color: rrr! > crr ? AppColors.error : AppColors.success),
        ],
      ],
    );
  }
}

class _RateChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RateChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(
                fontSize: 11, color: color,
                fontWeight: FontWeight.w600, letterSpacing: 0.5,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 12, color: color,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                )),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return A7Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 8),
          ],
          Text(value,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              )),
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            )),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Role Badge ───────────────────────────────────────────────────────────────

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (role) {
      'organizer' => (AppColors.secondary, 'ORGANIZER'),
      'captain' => (AppColors.primary, 'CAPTAIN'),
      'scorer' => (AppColors.info, 'SCORER'),
      _ => (AppColors.textMuted, 'PLAYER'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          )),
    );
  }
}

// ─── Over Display ─────────────────────────────────────────────────────────────

class OverBallDisplay extends StatelessWidget {
  final List<int> currentOverRuns;
  final bool hasWicket;

  const OverBallDisplay({
    super.key,
    required this.currentOverRuns,
    required this.hasWicket,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (i) {
        if (i >= currentOverRuns.length) {
          return _BallCircle(value: '', isEmpty: true);
        }
        final v = currentOverRuns[i];
        return _BallCircle(value: v == -1 ? 'W' : '$v', isWicket: v == -1);
      }),
    );
  }
}

class _BallCircle extends StatelessWidget {
  final String value;
  final bool isEmpty;
  final bool isWicket;

  const _BallCircle({
    required this.value,
    this.isEmpty = false,
    this.isWicket = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color = isEmpty
        ? AppColors.bgInput
        : isWicket
            ? AppColors.wicket
            : value == '4'
                ? AppColors.four
                : value == '6'
                    ? AppColors.six
                    : AppColors.bgElevated;

    return Container(
      width: 36, height: 36,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isEmpty ? AppColors.border : color,
          width: isEmpty ? 1.5 : 0,
        ),
      ),
      child: Center(
        child: Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isEmpty
                  ? AppColors.textMuted
                  : Colors.white,
            )),
      ),
    );
  }
}
