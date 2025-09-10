import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TagList extends StatefulWidget {
  final List<String> tags;
  List<String> displayTags = [];
  BuildContext context;
  Function(String) onTagSelected = (String tag) {};
  String? selectedCategory;
  ScrollController? scrollController;

  TagList({
    required this.tags,
    required this.context,
    required this.onTagSelected,
    required this.selectedCategory,
    this.scrollController,
    Key? key,
  }) : super(key: key) {
    displayTags = tags;
  }

  @override
  State<TagList> createState() => _TagListState();
}

class _TagListState extends State<TagList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.category,
                color: Theme.of(context).colorScheme.surface,
              ),
              const SizedBox(width: 16),
              Text(
                AppLocalizations.of(context).selectCategory,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).search,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  widget.displayTags = widget.tags
                      .where(
                        (tag) =>
                            tag.toLowerCase().contains(value.toLowerCase()),
                      )
                      .toList();
                } else {
                  widget.displayTags = widget.tags;
                }
              });
            },
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController ?? ScrollController(),
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.allCategories),
                leading: widget.selectedCategory == null
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.surface,
                      )
                    : Icon(
                        Icons.label_outline,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                onTap: () {
                  setState(() => widget.selectedCategory = null);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...widget.displayTags.map(
                (category) => ListTile(
                  title: Text(category),
                  leading: widget.selectedCategory == category
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.label_outline),
                  onTap: () {
                    setState(() => widget.selectedCategory = category);
                    widget.onTagSelected(category);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
