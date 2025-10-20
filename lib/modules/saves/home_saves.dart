import 'package:cashly/data/dao/month_dao.dart';
import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/dao/saves_dao.dart';
import 'package:cashly/data/models/saves.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/saves/logic/saves_service.dart';
import 'package:cashly/modules/saves/widgets/saves_widgets.dart';
import 'package:flutter/material.dart';

//statefull widget that shows a list of saves
class HomeSaves extends StatefulWidget {
  HomeSaves({super.key}) {
    final _db = SqliteService().db;
    savesService = SavesService(
      _db.savesDao,
      _db.monthDao,
      _db.movementValueDao,
    );
  }
  late SavesService savesService;
  List<Saves> saves = [];

  @override
  State<HomeSaves> createState() => _HomeSavesState();
}

class _HomeSavesState extends State<HomeSaves> {
  bool _hasInitialSave = false;

  @override
  void initState() {
    widget.savesService.getSaves().then((value) {
      setState(() {
        widget.saves = value;
      });

      widget.savesService.getSavesByIsInitialValue().then((value) {
        setState(() {
          _hasInitialSave = value.isNotEmpty;
        });
      });
    });

    super.initState();
  }

  void refreshSavesList() async {
    final saves = await widget.savesService.getSaves();
    setState(() {
      widget.saves = saves;
    });
  }

  void generateSaves() async {
    if (widget.saves.isEmpty) {
      await widget.savesService.generateAllSaves();
      final saves = await widget.savesService.getSaves();
      setState(() {
        widget.saves = saves;
      });
    } else {
      await widget.savesService.generateRemainingSaves();
      final saves = await widget.savesService.getSaves();
      setState(() {
        widget.saves = saves;
      });
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saves generated successfully')));
  }

  void refreshSaves(DateTime date) async {
    //borra el save de widget.saves que tenga el mismo año y mes que date y ejecuta generateRemainingSaves
    Saves _s = widget.saves.firstWhere(
      (save) => save.date.year == date.year && save.date.month == date.month,
    );
    await widget.savesService.deleteSave(_s);
    widget.saves.remove(_s);
    await widget.savesService.generateRemainingSaves();

    widget.saves = await widget.savesService.getSaves();
    setState(() {});
  }

  void _refreshDatePopUp() async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      refreshSaves(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          if (!_hasInitialSave)
            SavesWidgets.AddSaveButton(
              context: context,
              onPressed: (amount) {
                widget.savesService.addSave(amount);
                _hasInitialSave = true;
                refreshSavesList();
              },
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: generateSaves,
            label: Text('Generate remaining saves'),
            icon: Icon(Icons.refresh),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshDatePopUp,
            label: Text('Refresh saves for a month'),
            icon: Icon(Icons.date_range),
          ),
          const SizedBox(height: 16),
          SavesWidgets.LinearChart(widget.saves),
        ],
      ),
    );
  }
}
