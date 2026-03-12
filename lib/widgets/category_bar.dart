import 'package:flutter/material.dart';

/* This widget represents a horizontal category bar that allows users to select
different categories. It takes a list of category names, the index of the
currently selected category, and a callback function that is called when a category
is selected. The selected category is highlighted with a different color and font
weight. */
class CategoryBar extends StatelessWidget {
  /* The constructor for CategoryBar, which takes a key as an optional parameter, as
  well as the list of categories, the index of the selected category, and the
  callback function for when a category is selected. These parameters allow the
  CategoryBar to display the categories and handle user interactions. */
  final List<String> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  /* The constructor for CategoryBar, which takes a key as an optional parameter, as
  well as the list of categories, the index of the selected category, and the
  callback function for when a category is selected. These parameters allow the
  CategoryBar to display the categories and handle user interactions. */
  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  /* The build method constructs the UI for the CategoryBar. It creates a container
  with a specific height, padding, background color, and rounded corners. Inside
  the container, it generates a row of category names based on the provided list of
  categories. Each category is wrapped in an InkWell widget to make it tappable, and
  the selected category is styled differently to indicate that it is active. When a
  category is tapped, the onCategorySelected callback is called with the index of the
  selected category. */
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(categories.length, (index) {
          final isSelected = index == selectedIndex;
          return InkWell(
            onTap: () => onCategorySelected(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.red.shade400
                      : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
