import 'dart:async';

import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:quiet/component.dart';
import 'package:quiet/model/model.dart';
import 'package:quiet/pages/playlist/music_list.dart';
import 'package:quiet/part/part.dart';

import 'dialog_selector.dart';

typedef MusicDeletionCallback = Future<bool> Function(List<Music> selected);

///多选歌曲
class PlaylistSelectionPage extends StatefulWidget {
  const PlaylistSelectionPage({
    Key? key,
    required this.list,
    this.onDelete,
  }) : super(key: key);

  final List<Music>? list;

  ///null if do not track delete operation
  final MusicDeletionCallback? onDelete;

  @override
  PlaylistSelectionPageState createState() {
    return PlaylistSelectionPageState();
  }
}

class PlaylistSelectionPageState extends State<PlaylistSelectionPage> {
  bool allSelected = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  final List<Music> selectedList = [];

  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text("已选择${selectedList.length}项"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                allSelected = !allSelected;
                if (allSelected) {
                  selectedList.clear();
                  selectedList.addAll(widget.list!);
                } else {
                  selectedList.clear();
                }
              });
            },
            child: Text(allSelected ? "取消全选" : "全选",
                style: Theme.of(context).primaryTextTheme.bodyText2),
          )
        ],
      ),
      body: MusicTileConfiguration(
        musics: widget.list!,
        onMusicTap: (context, item) {
          setState(() {
            if (!selectedList.remove(item)) {
              selectedList.add(item);
            }
            if (selectedList.length == widget.list!.length) {
              allSelected = true;
            } else {
              allSelected = false;
            }
          });
        },
        child: ListView.builder(
            controller: controller,
            itemCount: widget.list!.length,
            itemBuilder: (context, index) {
              debugPrint("build item $index");
              final item = widget.list![index];
              final checked = selectedList.contains(item);
              return _SelectionItem(music: item, selected: checked);
            }),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Material(
      elevation: 5,
      child: ButtonBar(
        alignment: MainAxisAlignment.spaceAround,
        buttonTextTheme: ButtonTextTheme.normal,
        children: [
          TextButton(
            onPressed: () async {
              await Stream.fromIterable(selectedList).forEach((e) {
                context.player.insertToNext(e.metadata);
              });
              showSimpleNotification(Text("已添加${selectedList.length}首歌曲"));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_outline),
                const SizedBox(height: 2.0),
                Text(context.strings.playInNext)
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final bool? succeed = await PlaylistSelectorDialog.addSongs(
                  context, selectedList.map((m) => m.id).toList());
              if (succeed == null) {
                return;
              }
              if (succeed) {
                showSimpleNotification(Text("已成功收藏${selectedList.length}首歌曲"));
              } else {
                showSimpleNotification(
                  Text(context.strings.addToPlaylistFailed),
                  background: Theme.of(context).errorColor,
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_box),
                const SizedBox(height: 2.0),
                Text(context.strings.addToPlaylist)
              ],
            ),
          ),
          if (widget.onDelete != null)
            TextButton(
              onPressed: () async {
                final succeed = await showLoaderOverlay(
                    context, widget.onDelete!(selectedList));
                if (succeed) {
                  setState(() {
                    widget.list!.removeWhere((v) => selectedList.contains(v));
                    selectedList.clear();
                  });
                }
                if (succeed) {
                  showSimpleNotification(Text("已删除${selectedList.length}首歌曲"),
                      background: Theme.of(context).errorColor);
                } else {
                  showSimpleNotification(
                    Text(context.strings.failedToDelete),
                    leading: const Icon(Icons.error),
                    background: context.theme.errorColor,
                  );
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline),
                  const SizedBox(height: 2.0),
                  Text(context.strings.delete),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionItem extends StatelessWidget {
  const _SelectionItem({Key? key, required this.music, required this.selected})
      : super(key: key);

  final Music music;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          MusicTileConfiguration.of(context).onMusicTap!(context, music),
      child: IgnorePointer(
        child: Row(
          children: <Widget>[
            const SizedBox(width: 16),
            Checkbox(
                value: selected,
                onChanged: (v) => {
                      /*ignored pointer ,so we do not handle this event*/
                    }),
            const SizedBox(width: 4),
            Expanded(child: MusicTile(music)),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
