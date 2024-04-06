import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  final String name;
  final String description;
  final Widget child;
  final Function() onPressed;
  final Color color;
  final Color colorText;
  const CardWidget(
      {super.key,
      required this.name,
      required this.description,
      required this.child,
      required this.onPressed,
      required this.color,
      required this.colorText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.2,
          child: InkWell(
            onTap: () {
              onPressed();
            },
            child: Card(
              color: color,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.30,
                        height: MediaQuery.of(context).size.height * 0.30,
                        child: child,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 0,
                            child: Text(
                              name,
                              style: TextStyle(fontSize: 18, color: colorText),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              child: Text(
                                description,
                                style: TextStyle(fontSize: 15, color: colorText),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
