import 'package:flutter/material.dart';

class RoundedIcon extends StatelessWidget {
  const RoundedIcon({ Key? key,required this.imageUrl }) : super(key: key);
  final String imageUrl;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,offset: Offset(0,2),blurRadius: 0.6
            ),
          ],
          image: DecorationImage(
            image: AssetImage(imageUrl),
          )
        ),
      ),
    );
  }
}