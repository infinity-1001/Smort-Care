import 'package:flutter/material.dart';
import 'edit_medication_screen.dart';
import 'smort_status_card.dart';

class MedicationList extends StatelessWidget {
  final List<Map<String, dynamic>> medications;
  final Function(String) onDelete;
  final String smortId;
  final Function() onUpdate;
  final VoidCallback onDisconnect;

  const MedicationList({
    Key? key,
    required this.medications,
    required this.onDelete,
    required this.smortId,
    required this.onUpdate,
    required this.onDisconnect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SmortStatusCard(
          smortId: smortId,
          onDisconnect: onDisconnect,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            return Dismissible(
              key: Key(medication['id']),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                onDelete(medication['id']);
              },
              confirmDismiss: (DismissDirection direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirm"),
                      content: const Text("Are you sure you want to delete this medication?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("CANCEL"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              background: Container(
                color: Colors.red,
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                ),
              ),
              child: Card(
                child: ListTile(
                  title: Text(
                    medication['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Section: '),
                            TextSpan(
                              text: '${medication['sectionNumber']}',
                              style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Time: '),
                            TextSpan(
                              text: medication['time'],
                              style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Text('Set by: ${medication['setBy']['name']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMedicationScreen(
                                smortId: smortId,
                                medicationId: medication['id'],
                                medicationData: medication,
                              ),
                            ),
                          );
                          if (result == true) {
                            onUpdate();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onDelete(medication['id']),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
