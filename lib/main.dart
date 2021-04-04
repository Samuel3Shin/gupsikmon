import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:gupsikmon/ad_manager.dart';
import 'package:firebase_admob/firebase_admob.dart';

import 'package:csv/csv.dart';

const List<String> mealCodeToName = ["", "아침", "점심", "저녁"];
const List<String> dateToWeekDay = [
  "",
  "월요일",
  "화요일",
  "수요일",
  "목요일",
  "금요일",
  "토요일",
  "일요일"
];

List<Post> parsePost(String reponseBody) {
  final parsed = json.decode(reponseBody);
  return parsed['mealServiceDietInfo'][1]['row']
      .map<Post>((json) => Post.fromJson(json))
      .toList();
}

Future<List<Post>> fetchPost() async {
  final response = await http.get(Uri.parse(
      'https://open.neis.go.kr/hub/mealServiceDietInfo?KEY=82ab38c7fd554ac7935f6c059c50f380&Type=json&&ATPT_OFCDC_SC_CODE=J10&SD_SCHUL_CODE=7530184&&MLSV_YMD=202104'));
  // print(response.body)
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
  final String calorie;
  final String nutrition;

  Post({this.mealCode, this.date, this.dish, this.calorie, this.nutrition});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      mealCode: int.parse(json['MMEAL_SC_CODE']),
      date: json['MLSV_YMD'] as String,
      dish: json['DDISH_NM'] as String,
      calorie: json['CAL_INFO'] as String,
      nutrition: json['NTR_INFO'] as String,
    );
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

  List<List<dynamic>> data = [];

  // This function is triggered when the floating button is pressed
  void _loadCSV() async {
    final _rawData = await rootBundle.loadString("assets/school_info.csv");
    List<List<dynamic>> _listData = CsvToListConverter().convert(_rawData);
    setState(() {
      data = _listData;
    });
  }

  BannerAd _bannerAd;
  void _loadBannerAd() {
    _bannerAd
      ..load()
      ..show(anchorType: AnchorType.bottom);
  }

  @override
  void initState() {
    super.initState();

    _loadCSV();

    // Initialize the AdMob SDK
    FirebaseAdMob.instance.initialize(appId: AdManager.appId);

    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.fullBanner,
    );

    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('안산동산고등학교'),
      ),
      body: FutureBuilder<List<Post>>(
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
    );
  }
}

class CustomPostItem extends StatelessWidget {
  const CustomPostItem({
    Key key,
    this.mealCode,
    this.date,
    this.dish,
    this.calorie,
    this.nutrition,
  }) : super(key: key);

  final int mealCode;
  final String date;
  final String dish;
  final String calorie;
  final String nutrition;

  @override
  Widget build(BuildContext context) {
    var dishList = dish.split('<br/>');
    var dishBuffer = new StringBuffer();

    for (String item in dishList) {
      var allergyNumList = item.split('.');
      var firstOne = allergyNumList[0];
      var menuName = firstOne;
      var firstAllergyInfo = '';

      menuName = menuName.trim();

      dishBuffer.write(menuName);
      dishBuffer.write('\n');
    }

    DateTime dateToday = DateTime.parse(date);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: <Widget>[
          Row(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  mealCodeToName[mealCode],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ),
              Column(
                children: [
                  Text(date),
                  Text(dateToWeekDay[dateToday.weekday]),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(dishBuffer.toString()),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('칼로리: $calorie'),
          ),
        ],
      ),
    );
  }
}

class PostsList extends StatelessWidget {
  final List<Post> posts;
  PostsList({Key key, this.posts}) : super(key: key);

  Widget _buildItemWidget(Post post) {
    return CustomPostItem(
        mealCode: post.mealCode,
        date: post.date,
        dish: post.dish,
        calorie: post.calorie,
        nutrition: post.nutrition);
  }

  @override
  Widget build(BuildContext context) {
    posts.sort((a, b) => a.date.compareTo(b.date));

    //TODO: 지난 날은 지워야한다. or 오늘 날짜로 스크롤을 내려야한다.
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
