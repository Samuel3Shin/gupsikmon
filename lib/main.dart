import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

List<Post> parsePost(String reponseBody) {
  final parsed = json.decode(reponseBody);
  print("@@@@@@@@@");
  print(parsed);
  return parsed['mealServiceDietInfo'][1]['row']
      .map<Post>((json) => Post.fromJson(json))
      .toList();
}

Future<List<Post>> fetchPost() async {
  final response = await http.get(Uri.parse(
      'https://open.neis.go.kr/hub/mealServiceDietInfo?KEY=82ab38c7fd554ac7935f6c059c50f380&Type=json&&ATPT_OFCDC_SC_CODE=J10&SD_SCHUL_CODE=7530184&&MLSV_YMD=202003'));
  // print(response.body);
  if (response.statusCode == 200) {
    // 만약 서버로의 요청이 성공하면, JSON을 파싱합니다.
    return parsePost(response.body);
  } else {
    // 만약 요청이 실패하면, 에러를 던집니다.
    throw Exception('Failed to load post');
  }
}

class Post {
  final int mealCode;
  final String date;
  final String dish;

  // final String breakfast;

  // final String lunch;
  // final String dinner;

  // final int userId;
  // final int id;
  // final String title;
  // final String body;
  //
  //     for (int i = 0;
  //     i <
  //         int.parse(json['mealServiceDietInfo'][0]['head'][0]
  //                 ['list_total_count']
  //             .toString());
  //     ++i) {
  //   tmp = tmp +
  //       json['mealServiceDietInfo'][1]['row'][i]['DDISH_NM'].toString() +
  //       "\n";
  // }

  Post({this.mealCode, this.date, this.dish});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
        mealCode: int.parse(json['MMEAL_SC_CODE']),
        date: json['MLSV_YMD'] as String,
        dish: json['DDISH_NM'] as String);
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: Gupsik(),
        builder: (BuildContext context, Widget widget) {
          return new Padding(
              child: widget, padding: new EdgeInsets.only(bottom: 60));
        });
  }
}

class Gupsik extends StatefulWidget {
  Gupsik({Key key}) : super(key: key);

  @override
  _GupsikState createState() => _GupsikState();
}

class _GupsikState extends State<Gupsik> {
  Future<Post> post;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: Text('안산동산고등학교'),
      ),
      body: Center(
        child: FutureBuilder<List<Post>>(
          future: fetchPost(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print(snapshot.error);
            }

            // 기본적으로 로딩 Spinner를 보여줍니다.
            return snapshot.hasData
                ? PostsList(posts: snapshot.data)
                : CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

class PostsList extends StatelessWidget {
  final List<Post> posts;

  PostsList({Key key, this.posts}) : super(key: key);

  Widget _buildItemWidget(Post post) {
    return ListTile(
      onTap: () {
        // Clipboard.setData(new ClipboardData(text: "${clip.title}"));
        // Fluttertoast.showToast(
        //     msg: "Copied",
        //     toastLength: Toast.LENGTH_SHORT,
        //     gravity: ToastGravity.BOTTOM,
        //     timeInSecForIosWeb: 1,
        //     backgroundColor: Colors.black45,
        //     textColor: Colors.white,
        //     fontSize: 16.0);
      },
      title: Text(
        post.dish,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: posts.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildItemWidget(posts[index]);
      },
      separatorBuilder: (context, index) {
        return const Divider(height: 0);
      },
    );
  }
}
