# Spoiler

Spoiler widget for flutter.

## HowTo:
```dart
child: Spoiler(
            openCurve: Curves.elasticOut,
            closeCurve: Curves.elasticIn,
            header: Text("Tools", style: TextStyle(color: Colors.white)),
            child: GameControl()
```

## TODO:
 - [x] Custom header. 
 - [ ] Custom open header and custom close header.
 - [ ] On open callback with header height and child height arguments.
 - [ ] On close callback with header height and child height arguments.
 - [ ] Get only header height for spoiler in spoiler widgets.
 - [ ] Make Spoilers widget with calback that has all headers height and  all childs height.
