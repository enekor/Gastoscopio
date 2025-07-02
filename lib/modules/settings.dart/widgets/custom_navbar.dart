import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<CustomNavigationDestination> destinations;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final double height;
  final Duration animationDuration;
  final double elevation;
  final bool isOpaque;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Border? border;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.backgroundColor,
    this.indicatorColor,
    this.height = 80,
    this.animationDuration = const Duration(milliseconds: 500),
    this.elevation = 3,
    this.isOpaque = false,
    this.margin,
    this.borderRadius,
    this.border,
  }) : super(key: key);

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Mostrar el indicador inmediatamente en la posición inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void didUpdateWidget(CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          widget.margin ??
          EdgeInsets.only(
            left: 24.0,
            right: widget.selectedIndex != 2 ? 75.0 : 24.0,
            bottom: 18.0,
          ),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
        border: widget.border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: widget.elevation * 2,
            offset: Offset(0, widget.elevation),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
        child: Container(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                widget.destinations.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final CustomNavigationDestination destination = entry.value;
                  final bool isSelected = index == widget.selectedIndex;

                  return Expanded(
                    child: _buildNavigationItem(
                      context,
                      destination,
                      isSelected,
                      index,
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    CustomNavigationDestination destination,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => widget.onDestinationSelected(index),
      child: Container(
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Indicador de selección
            if (isSelected)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned(
                    top: 6, // Centrado como mencionaste
                    child: Container(
                      width: 64 * _animation.value,
                      height: 32 * _animation.value,
                      decoration: BoxDecoration(
                        color:
                            widget.indicatorColor ??
                            Theme.of(context).colorScheme.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
              ),
            // Icono
            AnimatedSwitcher(
              duration: widget.animationDuration,
              child: Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                key: ValueKey(isSelected),
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase para definir los destinos de navegación
class CustomNavigationDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const CustomNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
