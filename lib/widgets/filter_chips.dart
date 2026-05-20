import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';

class FilterChipsWidget extends StatelessWidget {
  const FilterChipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        if (provider.khatas.isEmpty) {
          return const SizedBox.shrink();
        }

        List<String> options = ['সব'];
        options.addAll(provider.khatas.map((k) => k.name).toList());

        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final khataName = options[index];
              final isSelected = provider.selectedKhataFilter == khataName;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(khataName),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    provider.setKhataFilter(khataName);
                  },
                  selectedColor: Colors.green.shade100,
                  checkmarkColor: Colors.green.shade800,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.green.shade900 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
