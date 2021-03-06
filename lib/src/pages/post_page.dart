import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:android_intent/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appavailability/flutter_appavailability.dart';

import 'package:halasat_cinema_mobile/src/const.dart';
import 'package:halasat_cinema_mobile/src/models/post.dart';
import 'package:halasat_cinema_mobile/src/models/post_list.dart';
import 'package:halasat_cinema_mobile/src/models/season.dart';
import 'package:halasat_cinema_mobile/src/services/vodu.dart';
import 'package:halasat_cinema_mobile/src/widgets/post_card.dart';
// import 'package:simple_permissions/simple_permissions.dart';

class PostPage extends StatefulWidget {
  PostPage({Key key, @required this.postListItem}) : super(key: key);

  final PostListItem postListItem;

  @override
  _PostPageState createState() {
    return _PostPageState();
  }
}

class _PostPageState extends State<PostPage> {
  static const platform = const MethodChannel('mxplayer');

  Future<Post> post;
  List<Season> seasons;

  @override
  void initState() {
    int id = int.parse(widget.postListItem.id);
    PostListItem item = widget.postListItem;

    post = fetchPost(id);

    if (item.type == '1') {
      int id = int.parse(item.id);
      fetchSeries(id).then(
        (data) => setState(() {
              seasons = data;
            }),
      );
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _checkPlayerIsAvailable(context);

    return Scaffold(
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder(
      future: post,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final Post item = snapshot.data;
          final PostListItem movie = item.movies[0];

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                floating: true,
                expandedHeight: 250.0,
                flexibleSpace: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    FadeInImage(
                      height: 300,
                      fit: BoxFit.cover,
                      image: NetworkImage('$kVoduBase/${movie.background}'),
                      placeholder:
                          AssetImage('assets/featured-placeholder.jpg'),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(.2),
                            Colors.blue.withOpacity(.3)
                          ],
                        ),
                      ),
                    ),
                    !(movie.type == '1')
                        ? Center(
                            child: GestureDetector(
                              onTap: () {
                                final String url = movie.url.isEmpty
                                    ? movie.url360.isEmpty
                                        ? movie.url720
                                        : movie.url360
                                    : movie.url;

                                _launchVideo(
                                    url: url,
                                    title: movie.title,
                                    subtitlesUrl: movie.srt);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor
                                      .withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 80.0,
                                  color: Theme.of(context).accentColor,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildTitle(context, movie),
                    ExpansionTile(
                      title: Column(
                        children: <Widget>[
                          InfoRow(
                            title: 'Story',
                            data: movie.story,
                          ),
                        ],
                      ),
                      children: <Widget>[
                        _buildInfoList(context, movie),
                      ],
                    ),
                    seasons != null ? _buildSeasonList(context) : SizedBox(),
                    Column(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(bottom: 5.0),
                          margin: EdgeInsets.only(bottom: 8.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 2.0,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                          child: Text(
                            'Recommended',
                            style: Theme.of(context).textTheme.body1,
                          ),
                        ),
                        _buildRecommendedRow(context, item),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _checkPlayerIsAvailable(BuildContext context) async {
    try {
      await AppAvailability.checkAvailability(kMXPlayer);
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text('MX Player is required!'),
              content: Text('Do you want to install MX Player?'),
              actions: <Widget>[
                FlatButton(
                  child: Text('CANCEL'),
                  textColor: Theme.of(context).textTheme.body1.color,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                RaisedButton(
                  child: Text('INSTALL'),
                  textColor: Theme.of(context).textTheme.body1.color,
                  onPressed: () {
                    AndroidIntent intent = AndroidIntent(
                      action: 'action_view',
                      data: Uri.encodeFull('market://details?id=' + kMXPlayer),
                    );
                    intent.launch();
                  },
                )
              ],
            ),
      );
    }
  }

  Container _buildTitle(BuildContext context, PostListItem movie) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width - 80.0,
            child: Text(
              movie.title,
              style: Theme.of(context).textTheme.title,
            ),
          ),
          Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 3.0),
                child: Text(
                  movie.imdbrate,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle
                      .copyWith(color: Colors.grey),
                ),
              ),
              Icon(
                Icons.star,
                color: Theme.of(context).accentColor,
                size: Theme.of(context).textTheme.subtitle.fontSize,
              ),
            ],
          )
        ],
      ),
    );
  }

  Padding _buildInfoList(BuildContext context, PostListItem movie) {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18.0),
      child: Column(
        children: <Widget>[
          InfoRow(
            title: 'Year',
            data: movie.year,
          ),
          InfoRow(
            title: 'Category',
            data: movie.category,
          ),
          InfoRow(
            title: 'Genre',
            data: movie.genre,
          ),
          InfoRow(
            title: 'Director',
            data: movie.director,
          ),
          InfoRow(
            title: 'Cast',
            data: movie.cast,
          ),
          InfoRow(
            title: 'Rated',
            data: movie.mpr,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedRow(BuildContext context, Post item) {
    return Container(
      height: 310.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: item.other.length,
        itemBuilder: (BuildContext context, int index) {
          final PostListItem other = item.other[index];
          return PostCard(
            postListItem: other,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostPage(postListItem: other),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSeasonList(BuildContext context) {
    return Column(
      children: seasons
          .map((Season item) => _buildEpisodeList(context, item))
          .toList(),
    );
  }

  Widget _buildEpisodeList(BuildContext context, Season season) {
    return ExpansionTile(
      title: Text(season.title),
      children: season.episode.map((Episode episode) {
        return ListTile(
          title: Text(episode.title),
          onTap: () {
            final String url = episode.url.isEmpty
                ? episode.url360.isEmpty ? episode.url720 : episode.url360
                : episode.url;

            _launchVideo(
              url: url,
              title: widget.postListItem.title + ' ' + episode.title,
            );
          },
        );
      }).toList(),
    );
  }

  Future<void> _launchVideo(
      {@required String url,
      String title = 'Episode',
      String subtitlesUrl}) async {
        
    await platform.invokeMethod(
      'launch_player',
      {'url': url, 'title': title, 'subtitlesUrl': subtitlesUrl},
    );
    // AndroidIntent intent = AndroidIntent(
    //   action: 'action_view',
    //   data: Uri.encodeFull(url),
    //   package: kMXPlayer,
    //   arguments: {
    //     'title': title,
    //     'filename': title,
    //     // 'subs': [Uri.encodeFull(subtitle)],
    //     // 'subs.enable': [Uri.encodeFull(subtitle)],
    //     // 'subs.name': [subtitle]
    //   },
    // );
    // await SimplePermissions.checkPermission(Permission.WriteExternalStorage);
    // await SimplePermissions.checkPermission(Permission.ReadExternalStorage);
    // await _downloadFile(subtitle, title + '.srt');
    // await intent.launch();
  }

  static HttpClient httpClient = new HttpClient();

  Future<File> _downloadFile(String url, String filename) async {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = '/storage/emulated/0/Subtitles';
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    Key key,
    @required this.title,
    @required this.data,
    this.bottomPadding = 5.0,
    this.spaceBetween = 8.0,
  }) : super(key: key);

  final String title;
  final String data;
  final double bottomPadding;
  final double spaceBetween;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: spaceBetween),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.0,
                color: Theme.of(context).textTheme.caption.color,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          Flexible(
            child: Text(data, style: Theme.of(context).textTheme.body1),
          ),
        ],
      ),
    );
  }
}
