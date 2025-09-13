import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/models/alert.dart';
import 'package:pawtech/providers/alert_provider.dart';
import 'package:pawtech/widgets/alert_card.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = Provider.of<AlertProvider>(context);
    final allAlerts = alertProvider.alerts;
    final unreadAlerts = alertProvider.unreadAlerts;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Alerts & Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis, // Add this to handle very long text
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unreadAlerts.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            alertProvider.markAllAlertsAsRead();
                          },
                          icon: const Icon(Icons.done_all),
                          label: const Text('Mark All Read'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Unread'),
                        if (unreadAlerts.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${unreadAlerts.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'All Alerts'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              
              _buildAlertsList(
                context: context,
                alerts: unreadAlerts,
                emptyMessage: 'No unread alerts',
                isLoading: alertProvider.isLoading,
              ),
              
              
              _buildAlertsList(
                context: context,
                alerts: allAlerts,
                emptyMessage: 'No alerts found',
                isLoading: alertProvider.isLoading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsList({
    required BuildContext context,
    required List<Alert> alerts,
    required String emptyMessage,
    required bool isLoading,
  }) {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    
    return RefreshIndicator(
      onRefresh: () => alertProvider.fetchAlerts(),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyMessage,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return Dismissible(
                      key: Key(alert.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) {
                        alertProvider.deleteAlert(alert.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Alert deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                
                              },
                            ),
                          ),
                        );
                      },
                      child: AlertCard(
                        alert: alert,
                        onTap: () {
                          if (!alert.isRead) {
                            alertProvider.markAlertAsRead(alert.id);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

