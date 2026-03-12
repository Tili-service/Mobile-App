import 'package:flutter/material.dart';

/* This widget represents a set of sort buttons that allow users to sort items by
different criteria, such as price or name. It consists of a row with two buttons,
each displaying a title and an icon indicating that the items can be sorted. The
buttons are styled with a specific color and font weight to make them visually
distinct. When a button is tapped, it currently does not perform any action, but it
can be easily extended to implement sorting functionality in the future. */
class SortButtons extends StatelessWidget {
  /* The constructor for SortButtons, which takes a key as an optional parameter. */
  const SortButtons({super.key});

  /* The build method constructs the UI for the SortButtons. It creates a row
  with two sort buttons: one for sorting by price and one for sorting by name. Each
  button is created using the _sortButton helper method, which takes a title as a
  parameter and returns a widget representing the button. The buttons are separated
  by a SizedBox to provide spacing between them. */
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _sortButton("Prix"),
        const SizedBox(width: 30),
        _sortButton("Nom"),
      ],
    );
  }

  /* This helper method creates a sort button with the given title. It returns an
  InkWell widget that contains a row with the title and an icon. The onTap callback
  is currently empty, but it can be implemented to perform sorting actions when the
  button is tapped. The text and icon are styled with a specific color and font
  weight to make them visually distinct. */
  Widget _sortButton(String title) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5A8B8C),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.unfold_more,
            color: Color(0xFF5A8B8C),
            size: 20,
          ),
        ],
      ),
    );
  }
}
