import 'package:flutter/material.dart';
import 'package:pawtech/models/alert.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;

  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.parse(alert.timestamp);
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours} hours ago';
    } else {
      timeAgo = '${difference.inDays} days ago';
    }

    IconData alertIcon;
    Color alertColor;
    
    switch (alert.type) {
      case 'geofence_breach':
        alertIcon = Icons.location_off;
        alertColor = Colors.red;
        break;
      case 'low_battery':
        alertIcon = Icons.battery_alert;
        alertColor = Colors.orange;
        break;
      case 'inactivity':
        alertIcon = Icons.access_time;
        alertColor = Colors.amber;
        break;
      default:
        alertIcon = Icons.notifications;
        alertColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: alert.isRead ? null : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: alert.isRead
            ? BorderSide.none
            : BorderSide(color: alertColor.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  alertIcon,
                  color: alertColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.dogName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: alert.isRead ? null : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: alert.isRead ? null : FontWeight.bold,
                      ),
                    ),
                    if (!alert.isRead)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: alertColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

