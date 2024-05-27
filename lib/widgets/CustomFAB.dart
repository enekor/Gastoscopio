import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

FloatingActionButton CustomFAB({required Function onClick,required String text,required IconData icon,required bool extended}){
    return FloatingActionButton.extended(
      label: Text(text),
      onPressed: onClick(),
      icon: Icon(icon),
      isExtended: extended
    );
  }


 