import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:gupsikmon/ad_manager.dart';
import 'package:firebase_admob/firebase_admob.dart';

import 'package:csv/csv.dart';

const DISTRICT_KEY = 'DISTRICT';
const SCHOOL_CODE_KEY = 'SCHOOL_CODE';
const SCHOOL_NAME_KEY = 'SCHOOL_NAME';

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
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var district = prefs.getString(DISTRICT_KEY);
  var schoolCode = prefs.getString('SCHOOL_CODE');
  final response = await http.get(Uri.parse(
      'https://open.neis.go.kr/hub/mealServiceDietInfo?KEY=82ab38c7fd554ac7935f6c059c50f380&Type=json&&ATPT_OFCDC_SC_CODE=' +
          district +
          '&SD_SCHUL_CODE=' +
          schoolCode +
          '&&MLSV_YMD=202104'));
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
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  // This function is triggered when the floating button is pressed
  // TODO: 학교 정보는 학교 등록하는 상황 아니면, 굳이 먼저 load하지 않도록 해야 한다.
  void _loadCSV() async {
    final _rawData =
        await rootBundle.loadString("assets/school_info_20210424.csv");
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
        actions: <Widget>[
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: Search(this, data));
            },
            icon: Icon(Icons.search),
          ),
        ],
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

  void addSchoolInfoToSF(
      String district, String schoolCode, String schoolName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString(DISTRICT_KEY, district);
      prefs.setString(SCHOOL_CODE_KEY, schoolCode);
      prefs.setString(SCHOOL_NAME_KEY, schoolName);
    });
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

class Search extends SearchDelegate {
  final _GupsikState _gupsikState;
  final List<List<dynamic>> listExample;
  Search(this._gupsikState, this.listExample);

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  String selectedResult;

  @override
  Widget buildResults(BuildContext context) {
    return Container(
      child: Center(
        child: Text(selectedResult),
      ),
    );
  }

  List<List<dynamic>> recentList = [];

  @override
  Widget buildSuggestions(BuildContext context) {
    List<List<dynamic>> suggestionList = [];
    query.isEmpty
        ? suggestionList = recentList
        : suggestionList.addAll(listExample
            .where((element) => element.elementAt(2).contains(query)));

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {
            Fluttertoast.showToast(
                msg: '학교 정보가 ' +
                    suggestionList[index][2].toString() +
                    '로 등록되었습니다.',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.TOP,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black45,
                textColor: Colors.white,
                fontSize: 16.0);

            _gupsikState.addSchoolInfoToSF(
                suggestionList[index][0].toString(),
                suggestionList[index][1].toString(),
                suggestionList[index][2].toString());
          },
          title: Text(
            suggestionList[index].elementAt(2),
          ),
        );
      },
    );
  }
}
