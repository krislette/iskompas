import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 30, 30), 
        border: Border.all(color: Colors.grey.shade700), 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), 
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white), 
        cursorColor: Colors.white, 
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color.fromARGB(255, 197, 197, 197)), 
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Color.fromARGB(255, 197, 197, 197)), 
        ),
        onChanged: onChanged,
      ),
    );
  }
}
