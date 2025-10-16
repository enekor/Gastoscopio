import 'package:flutter/material.dart';

//statefull widget that shows a list of saves
class HomeSaves extends StatefulWidget {
  const HomeSaves({super.key});
  final SavesService _savesService;
  final List<Saves> _saves;


  initState() {
    _savesService = SavesService(new SavesDao(), new MonthDao(), new MovementValueDao());
    _savesService.generateSaves().then((value) {
        _saves = value;
    });
    super.initState();
  }

  @override
  State<HomeSaves> createState() => _HomeSavesState();
}

class _HomeSavesState extends State<HomeSaves> {
    //screen that shows a button to add a new save if _savesService.getSavesByIsInitialValue().isEmpty (with its form) and a linear chart for the values from _saves
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
            if (_savesService.getSavesByIsInitialValue().isEmpty)
            addSaveButton(context, (amount) {
                _savesService.addSave(amount);
            }),
            
            LinearChart(values: _saves.map((e) => e.amount).toList()),
        ],
      );
    }
  }
