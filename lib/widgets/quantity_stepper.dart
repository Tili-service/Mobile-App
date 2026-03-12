import 'package:flutter/material.dart';

/* This widget represents a quantity stepper, which allows users to increase or
decrease a quantity. It consists of a container with two buttons: one for
decreasing the quantity and one for increasing it. The buttons are styled with
a background color and rounded corners. When the buttons are tapped, they print
"Moins" or "Plus" to the console, indicating that the quantity should be
decreased or increased, respectively. */
class QuantityStepper extends StatelessWidget {
  /* The constructor for QuantityStepper, which takes a key as an optional parameter. */
  const QuantityStepper({super.key});

  /* The build method constructs the UI for the QuantityStepper. It creates a
  container with a specific background color and rounded corners. Inside the
  container, it creates a row with two InkWell widgets that serve as buttons for
  decreasing and increasing the quantity. Each button has an onTap callback that
  prints a message to the console when tapped. The buttons are separated by a
  vertical divider to visually distinguish them. */
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              print("Moins");
            },
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.remove),
            ),
          ),
          Container(
            width: 1,
            height: 15,
            color: Colors.grey,
          ),
          InkWell(
            onTap: () {
              print("Plus");
            },
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
