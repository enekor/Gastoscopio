import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
import 'package:flutter/material.dart';

class CreditCardHistoryScreen extends StatelessWidget {
  const CreditCardHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CreditCardService.getInstance();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Tarjetas'),
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, child) {
          final months = service.allMonths;
          
          if (months.isEmpty) {
            return const Center(
              child: Text('No hay historial disponible'),
            );
          }
          
          return ListView.builder(
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.calendar_month),
                ),
                title: Text('${month.month}/${month.year}'),
                subtitle: Text('Límite: ${month.limitAmount.toStringAsFixed(2)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show details for this month
                },
              );
            },
          );
        },
      ),
    );
  }
}
