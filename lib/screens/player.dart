import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kplayer/kplayer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  MusicPlayerState createState() => MusicPlayerState();
}

class MusicPlayerState extends State<MusicPlayer>
    with SingleTickerProviderStateMixin {
  List<String> songs = [];
  List<String> faviates = [];
  List<int> _currentIndex = [-1, -1];

  bool _isPlaying = false;
  bool inited = false;
  double timeValue = 0;
  double timeMax = 1000000;
  double vol = 0.5;
  ScrollController songsController = ScrollController();
  ScrollController faviatesController = ScrollController();
  late PlayerController _controller;
  int tabIndex = 0;
  List<Widget> pages = [];
  late SharedPreferences prefs;
  late TabController tabController;

  Future<void> requestPermissions() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw 'Storage permission not granted';
    }
  }

  Future<SharedPreferences> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  List<String> noDoubel(List<String> list) {
    Set<String> set = {...list};
    return set.toList(growable: true);
  }

  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);

    _initPrefs().then((prefs) async {
      songs = (await prefs.getStringList("songs"))!;
      songs = noDoubel(songs);
      faviates = (await prefs.getStringList("faviates"))!;
      setState(() {});
    });
  }

  Future<List<String>> pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return [];
    final directory = Directory(result);
    final files = await directory.list().toList();

    return files
        .where((file) => file.path.endsWith('.mp3'))
        .map((file) => file.path)
        .toList();
  }

  void _playOrPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      if (_controller == null) {
        initController();
      } else {
        _controller.play();
      }
      inited = true;
    } else {
      _controller.pause();
    }
  }

  void _nextSong() {
    setState(() {
      _currentIndex[tabController.index] =
          (_currentIndex[tabController.index] + 1) % songs.length;
      if (_controller != null) {
        _controller.dispose();
      }
      initController();
    });
  }

  void _previousSong() {
    setState(() {
      if (_controller != null) {
        _controller.dispose();
      }
      _currentIndex[tabController.index] =
          (_currentIndex[tabController.index] - 1 + songs.length) %
          songs.length;
      initController();
    });
  }

  void _removeSong(int index) {
    setState(() {
      if (tabController.index == 0) {
        songs.removeAt(index);
        if (_currentIndex[tabController.index] >= songs.length) {
          _currentIndex[tabController.index] = songs.length - 1;
        }
        prefs.setStringList("songs", noDoubel(songs));
      } else {
        faviates.removeAt(index);
        if (_currentIndex[tabController.index] >= faviates.length) {
          _currentIndex[tabController.index] = faviates.length - 1;
        }
        prefs.setStringList("faviates", noDoubel(faviates));
      }
    });
    setState(() {});
  }

  Future<void> addSong() async {
    pickFolder().then((files) {
      setState(() {
        songs.addAll(files);
        songs.remove("");

        // pages = [buildAll(songs), buildAll(songs.sublist(1, 11))];
      });
    });
    await prefs.setStringList("songs", noDoubel(songs));
  }

  Future<void> addFavorite(int index) async {
    setState(() {
      if (!faviates.contains(songs[index])) {
        faviates.add(songs[index]);
        faviates.remove("");
      }
    });
    await prefs.setStringList("faviates", noDoubel(faviates));
    await prefs.setStringList("songs", noDoubel(songs));
  }

  void _play(int index) {
    _currentIndex[tabController.index] = index;
    if (inited && _controller != null) {
      _controller.dispose();
    }
    initController();

    setState(() {
      _isPlaying = true;
    });
  }

  void initController() {
    if (tabController.index == 0) {
      _controller = Player.file(songs[_currentIndex[tabController.index]]);
    } else {
      _controller = Player.file(faviates[_currentIndex[tabController.index]]);
    }
    _controller.callback = (event) {
      setState(() {
        if (event == PlayerEvent.end) {
          _nextSong();
        } else if (event == PlayerEvent.position) {
          timeValue = (_controller.position.inMilliseconds.toDouble());
        } else if (event == PlayerEvent.duration) {
          timeMax = _controller.duration.inMilliseconds.toDouble();
        } else if (event == PlayerEvent.end) {
          _nextSong();
        }
      });
    };
    _controller.setVolume(vol);
    inited = true;
  }

  @override
  Widget build(BuildContext context) {
    //  Color iconColor = index == _currentIndex ? Colors.blue : Colors.white70;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 22,
        title: const SizedBox(
          height: 20,
          child: Text(
            'i悦',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(
              icon: Icon(
                Icons.music_note_outlined,
                size: 20,
                color: tabController.index == 0 ? Colors.blue : Colors.white70,
              ),
            ),
            Tab(
              icon: Icon(
                Icons.favorite,
                size: 20,
                color: tabController.index == 1 ? Colors.red : Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              buildSongs(context, songs, songsController),
              buildSongs(context, faviates, faviatesController),
            ],
          ),
        ),
        buildProcessBar(context),
        buildPlayController(context),
      ],
    );
  }

  Widget buildSongs(
    BuildContext context,
    List<String> songItems,
    ScrollController rollController,
  ) {
    return ListView.builder(
      controller: rollController,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      // primary: true,
      shrinkWrap: true,
      cacheExtent: 120,
      itemCount: songItems.length,

      itemBuilder: (context, index) {
        String songName = "";
        if (Platform.isWindows) {
          songName = songItems[index].split('\\').last;
        } else {
          songName = songItems[index].split('/').last;
        }
        int lindex = songName.lastIndexOf(".");
        if (lindex > 0) {
          songName = songName.substring(0, lindex);
        }
        Color textColor =
            index == _currentIndex[tabController.index]
                ? Colors.blue
                : Colors.white70;
        Color iconColor =
            index == _currentIndex[tabController.index]
                ? Colors.blue
                : Colors.white70;
        Color favirateColor =
            tabController.index == 0 && faviates.contains(songs[index])
                ? Colors.red
                : iconColor;
        return Container(
          height: 36,
          color:
              index == _currentIndex[tabController.index]
                  ? Colors.black12
                  : Colors.black,
          child: ListTile(
            onTap: () => _play(index),
            minVerticalPadding: 1,
            contentPadding: const EdgeInsets.all(2),
            hoverColor: Colors.black12,
            titleAlignment: ListTileTitleAlignment.top,
            isThreeLine: false,
            selected: index == _currentIndex[tabController.index],
            leading: IconButton(
              highlightColor: iconColor,
              icon: Icon(Icons.delete, size: 20),
              onPressed: () => _removeSong(index),
            ),
            title: Align(
              alignment: Alignment.topLeft,
              child: Text(
                songName,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            trailing:
                tabIndex == 0
                    ? IconButton(
                      icon: Icon(
                        Icons.favorite,
                        size: 20,
                        color: favirateColor,
                      ),
                      onPressed: () => addFavorite(index),
                    )
                    : Container(),
          ),
        );
      },
    );
  }

  Widget buildProcessBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            min: 0,
            max: 1,
            label: "$timeValue / $timeMax",
            value:
                timeMax < 100 || timeValue / timeMax > 1
                    ? 0
                    : timeValue / timeMax,
            onChanged: (double value) {
              setState(() {
                timeValue = value;
                double latValue = timeValue * timeMax;
                _controller!.seek(Duration(milliseconds: latValue.toInt()));
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildPlayController(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.spaceEvenly,
      runAlignment: WrapAlignment.center,
      children: [
        IconButton(
          onPressed: _previousSong,
          icon: const Icon(Icons.skip_previous, color: Colors.white70),
        ),
        IconButton(
          onPressed: _playOrPause,
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white70,
          ),
        ),
        IconButton(
          onPressed: _nextSong,
          icon: const Icon(Icons.skip_next, color: Colors.white70),
        ),
        IconButton(
          onPressed: addSong,
          icon: const Icon(Icons.add, color: Colors.white70),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.cable_rounded, color: Colors.white70),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.volume_up_outlined, color: Colors.white70),
        ),
        Slider(
          value: vol,
          min: 0,
          max: 1,
          onChanged: (value) {
            setState(() {
              vol = value;
              _controller!.setVolume(vol);
            });
          },
        ),
      ],
    );
  }
}
