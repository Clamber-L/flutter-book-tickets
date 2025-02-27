import 'package:flutter/material.dart';

class RowColumnListView extends StatelessWidget {
  const RowColumnListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              IgnorePointer(child: Opacity(opacity: 0.0, child: Item())),
              SizedBox(width: double.infinity),
              Positioned.fill(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) => Item(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Item extends StatelessWidget {
  const Item({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text("hello", style: TextStyle(fontSize: 32)),
          Text("hello", style: TextStyle(fontSize: 42)),
        ],
      ),
    );
  }
}
