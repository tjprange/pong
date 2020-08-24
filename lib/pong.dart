import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import './ball.dart';
import './bat.dart';

enum Direction { up, down, left, right}

class Pong extends StatefulWidget {
  @override
  _PongState createState() => _PongState();
}

class _PongState extends State<Pong> with SingleTickerProviderStateMixin {
  double increment = 5;
  Direction vDir = Direction.down;
  Direction hDir = Direction.right;

  int score = 0;


  // Hold value .5 - 1.5 to change ball speed and bounce angle
  double randX = 1;
  double randY = 1;

  // holds width and height of available screen
  double width;
  double height;

  // ball coordinates
  double posX;
  double posY;

  // vars for bat information
  double batWidth = 0;
  double batHeight = 0;
  double batPosition = 0;

  Animation<double> animation;
  AnimationController controller;

  @override
  void initState() {
    posX = 0;
    posY = 0;
    controller = AnimationController(
      duration: const Duration(seconds: 10000),
      vsync: this,
    );
    animation = Tween<double>(begin: 0, end: 100).animate(controller);
    animation.addListener(() { safeSetState(() {
      (hDir == Direction.right) ? posX += ((increment * randX).round()) : posX -= ((increment * randX).round());
      (vDir == Direction.down) ? posY += ((increment * randY).round()) : posY -= ((increment * randY).round());
    });
    checkBorders();
    });

    controller.forward();
    super.initState();
  }

  // This function will handle the ball movement and contact with the bat
  void checkBorders(){
    double diameter = 50;

    if (posX <= 0 && hDir == Direction.left){
      hDir = Direction.right;
      randX = randomNumber();
    }
    if (posX >= width - diameter && hDir == Direction.right){
      hDir = Direction.left;
      randX = randomNumber();
    }
    if (posY >= height - batHeight - diameter && vDir == Direction.down){
      if (posX >= (batPosition - diameter) && posX <= (batPosition + batWidth + diameter)){
        vDir = Direction.up;
        randY = randomNumber();
        safeSetState((){
          score++;
        });
      }
      else {
        controller.stop();
        //dispose();
        showMessage(context);
      }
    }
    if (posY <= 0 && vDir == Direction.up){
      vDir = Direction.down;
      randY = randomNumber();
    }
  }

  void moveBat(DragUpdateDetails update) {
    safeSetState((){
      // dx is horizontal delta, which can be positive or negative
      batPosition += update.delta.dx;
    });
  }

  // generate random number between .5 and 1.5
  double randomNumber() {
    var ran = new Random();
    int myNum = ran.nextInt(101);
    return (50 + myNum) / 100;
  }

  void showMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Game Over'),
          content: Text('Play Again?'),
          actions: <Widget>[
            FlatButton(
              child: Text('Yes'),
              // reset score and ball position
              onPressed: () {
                setState(() {
                  posX = 0;
                  posY = 0;
                  score = 0;
                });
                // pop AlertDialog off stack
                Navigator.of(context).pop();
                controller.repeat();
              }
            ),
            FlatButton(
              child: Text('No'),
              onPressed: (){
                //Navigator.of(context).pop();
                dispose();
                SystemNavigator.pop();
              },
            )
          ],
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    // Builds a widget tree that can depend on the parent widget's size
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      height = constraints.maxHeight;
      width = constraints.maxWidth;
      batWidth = width / 5;
      batHeight = height / 20;
      return Stack(children: <Widget>[
        // Controls where the child of a stack is positioned
        Positioned(
          top: 0,
          right: 24,
          child: Text('Score: ' + score.toString()),
        ),
        //A widget that controls where a child of a Stack is positioned.
        Positioned(
          child: Ball(),
          top: posY,
          left: posX,
        ),
        Positioned(bottom: 0,
            left: batPosition,
            child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails update) =>
                moveBat(update),
                child: Bat(batWidth, batHeight)))
      ]);
    });
  }

  void safeSetState(Function function){
    // mounted checks whether the state object is currently mounted
    // before calling initState() and until dispose() is called. Calling setState
    if (mounted && controller.isAnimating) {
      setState(() {
        function();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
