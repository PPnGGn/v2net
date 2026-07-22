import 'package:flutter/material.dart';
import 'package:v2net/app/theme.dart';
import 'package:v2net/core/formatters.dart';
import 'package:v2net/core/models/stored_subscription/stored_subscription.dart';
import 'package:v2net/core/models/vpn_server/vpn_server.dart';

class SubscriptionCard extends StatefulWidget {
  const SubscriptionCard({
    super.key,
    required this.stored,
    required this.selectedServerId,
    required this.isRefreshing,
    required this.onSelect,
    required this.onDelete,
    required this.onRefresh,
  });

  final StoredSubscription stored;
  final String? selectedServerId;
  final bool isRefreshing;
  final ValueChanged<VpnServer> onSelect;
  final VoidCallback onDelete;
  final VoidCallback? onRefresh;

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final sub = widget.stored.subscription;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray181F25,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.grayA9BAC6,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.stored.servers.length} серверов',
                          style: const TextStyle(
                            color: AppColors.grayA9BAC6,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Обновлено: ${formatUpdatedAt(sub.lastUpdatedAt)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isRefreshing)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    PopupMenuButton<void>(
                      color: AppColors.gray2E2E3A,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.grayA9BAC6,
                      ),
                      itemBuilder: (context) => [
                        if (widget.onRefresh != null)
                          PopupMenuItem(
                            onTap: widget.onRefresh,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: AppColors.grayA9BAC6,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Обновить подписку',
                                  style: TextStyle(color: AppColors.white),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          onTap: widget.onDelete,
                          child: const Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.redFF6A55,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Удалить подписку',
                                style: TextStyle(color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(color: AppColors.border, height: 1),
            for (final server in widget.stored.servers)
              _ServerRow(
                server: server,
                selected: server.id == widget.selectedServerId,
                onTap: () => widget.onSelect(server),
              ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({
    required this.server,
    required this.selected,
    required this.onTap,
  });

  final VpnServer server;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green19FF90.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? AppColors.green19FF90 : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            if (!startsWithFlagEmoji(server.title)) ...[
              Text(
                server.countryCode != 'XX'
                    ? countryFlag(server.countryCode)
                    : '🏳️',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                server.title,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.grayA9BAC6,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.green19FF90,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
