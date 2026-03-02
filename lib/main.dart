/* A STAND ALONE CADENCE CHECKER USING PIXEL 6 MOBILE ACCELEROMETERS
NEED TO BRING OVER SOME YAML STUFF AND MISCELLANEOUS IMPORTS BEFORE
EVEN GETTING STARTED  */

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

import 'dart:core';
import 'package:flutter/services.dart';
import 'dart:async';
//import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
//----------------------------------------------------------------------
void main() {
  runApp(const MyApp());
}
//----------------------------------------------------------------------
/* RM8 HOME PAGE WILL HAVE SEVERAL OPTIONS: BEGINS WITH "START COUNTER" */

// HOME ---------------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing',
      theme: ThemeData(
        // This is the theme of your application.
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF22D3EE),
          //background: Color(0xFF0F172A),
          surface: Color(0xFF1E293B),
          error: Color(0xFFF87171),
        ),

        dividerColor: const Color(0xFF334155),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE5E7EB), fontSize: 15),
          bodySmall: TextStyle(color: Color(0xFF94A3B8)),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        cardColor: const Color(0xFF1E293B),
      //  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

        home: const RM8(title: 'RM8 Home Page'),
        routes: {
          //'/first': (context) => const ERGOne(title: 'SPMCount'),
          '/2nd': (context) => const Report(title: 'Report'),},
        //'/3rd': (context) => const ERGOne(title: 'Summary '),
        );
        }}
/* TOTAL 4 SCREENS FOR RM8Lite */
//------------------------------------------------------------------------------
Timer? timer1;

final String reportLite = 'reportList';


//---------------------------------------------------------------------------
void startDelay() { // NOT WORKING TO DELAY ROWING START
  timer1 = Timer(const Duration(seconds: 5), () {
    //print("Fired once after 3 seconds");
  });
}
//-----------------------------------------------------------------------------



//------------------------------------------------------------------------------
class RM8 extends StatefulWidget {
  final String title;
  const RM8({super.key, required this.title});
  @override
  State<RM8> createState() => _RM8State();
  }
// INITIALIZE SCREEN-SHARED VARIABLES
double threshold = 1.3;
double smoothAlpha = .5;     // accel NOISE SMOOTHING PARAMETERS
double _currentSlider1Value = 250;
double _currentSlider2Value = 50;
double _currentSlider3Value = 28;
double _currentSlider4Value = 80;
// GLOBALS!! ??
List<int> strokeTimes = [];
List<double> liveCadence =[];

//?? 1 column 3 entrys each row as added ??
List <dynamic> strokeReport = [['time', 'strokeRate', 'power'],[]];
List <num> reportList = [0, 1, 2, 3, 4, 5, 6];
int elapsedMs = 0;   // is reset with each new entry
double pieceTimemin = 0.0;
double xpieceTimemin = 0.0;
double minPer500 = 0.0;
double xminPer500 = 0.0;
double avgCadence = 2.0;


//GLOBAL INITIAL DECLARATIONS NOT CHANGED BY ONCHANGE
// INITIALIZE CONTROLLER OBJECTS
final _thresholdcontroller = TextEditingController(text:'1.0');
final _smoothcontroller = TextEditingController(text:'.5');
// User and Rowing Lists combined for a csv file
// 26Feb change to declare all lists here
final List<Map<String, dynamic>> rows = [];
final List<Map<String, dynamic >> user =[];
// List<List<dynamic>> combinedReportLists = [user + rows];

/*============================================================================*/
// OPENING SCREEN SELECT NEXT SCREEN (ROWER SETUP OR DEFINE SPLITS)
class _RM8State extends State<RM8> {
  double currentSlider1 =0.0;
  double currentSlider2 =0.0;
  double currentSlider3 =0.0;
  String buttonText = 'Start (countdown)';
  int countdown = 5;
  //String buttonText = 'Start';


  @override
  void initState() {
    super.initState();
// SET CONTROLLER OBJECT TEXT PROPERTY OK
  _thresholdcontroller.text = '1.0'; // threshold.toString();
  _smoothcontroller.text = '.5'; //smoothAlpha.toString();
  }

  //------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    ButtonStyle style =
    ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
    return Scaffold(
      appBar: AppBar(
        title: Text('RM8Lite Feb 2026...'),
      ),
      body: Center(
          child: Row(
            children:<Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
    //---------------------------------------------------------------------
                  // FIRST SLIDER (CHOOSE PIECE LENGTH)
                  Text(
                    'Piece Length: ${_currentSlider1Value.round()}', // Display rounded value
                    style: const TextStyle(fontSize: 20),
                  ),
                  SizedBox( // TO SIZE SLIDER WIDGET
                    height: 26,
                    width:300,
                    child: Align(
                      alignment: Alignment.center,
                      child:
                      Slider(
                        value: _currentSlider1Value,
                        min: 0.0,
                        max: 2000.0,
                        divisions: 4, // Optional: Creates 4 discrete intervals (0, 20, 40, 60, 80, 100)
                        label: _currentSlider1Value.round().toString(), // Label that pops up when dragging the thumb
                        onChanged: (double newValue) {
                             _currentSlider1Value = newValue;
                            setState(() {
                              _currentSlider1Value;
                            });
                         // }
                        },
                      ),
                    ),    // TEXT
                  ),
//----------------------------------------------------------------
               // 2ND SLIDER (SET METERS PER STROKE)
              Text('Mtrs per Stroke: ${_currentSlider2Value.round()}', // Display rounded value
                style: const TextStyle(fontSize: 20),
              ),
              SizedBox(
                height: 26,
                width:300,
                  child: Align(
                    alignment: Alignment.center,
                    child:
                    Slider(
                      value: _currentSlider2Value,
                      min: 0.0,
                      max: 100.0,
                      divisions: 10, // Optional: Creates 10 discrete intervals (0, 20, 40, 60, 80, 100)
                      label: _currentSlider2Value.round().toString(), // Label that pops up when dragging the thumb
                      onChanged: (double newValue) {
                        _currentSlider2Value = newValue;
                          setState(() {
                            _currentSlider2Value;
                          });
                        //}
                      },
                     ),
                    ),    // TEXT
                  ),
//----------------------------------------------------------------
                  // CADENCE SLIDER
                  Text('Target Cadence: ${_currentSlider3Value.round()}', // Display rounded value
                    style: const TextStyle(fontSize: 20),
                  ),
                  SizedBox( // TO SIZE SLIDER WIDGET
                    height: 26,
                    width:300,
                    child: Align(
                      alignment: Alignment.center,
                      child:
                      Slider(
                        value: _currentSlider3Value,
                        min: 16,
                        max: 46,
                        divisions: 15,
                        label: _currentSlider3Value.round().toString(), // Label that pops up when dragging the thumb
                        onChanged: (double newValue) {
                          _currentSlider3Value = newValue;
                          setState(() {
                              _currentSlider3Value;
                            });
                         // }
                        },
                      ),
                    ),    // TEXT
                  ),
        // ----------------------------------------------------------------
                  // spacer
                  SizedBox(
                    height:10,
                    width: 100,
                  ),
        //-----------------------------------------------------------------
/* from chatGPT
int countdown = 5;
String buttonText = 'Start';

onPressed: () {
  countdown = 5;

  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (countdown == 0) {
      timer.cancel();

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ERGOne(
            title: 'Begin ERGOne Workout',
            threshold: threshold,
            smoothAlpha: smoothAlpha,
            currentSlider1: currentSlider1,
            currentSlider2: currentSlider2,
            currentSlider3: currentSlider3,
          ),
        ),
      );
    } else {
      setState(() {
        buttonText = countdown.toString();
        countdown--;
      });
    }
  });
}
 */

              SizedBox(
                height: 100, //height of button
                width:220, //width of button
                // START STROKE COUNTER..
                child:ElevatedButton(
                  style: style,
                  child:  Text (buttonText),
                    onPressed: () {
                      countdown = 5;
                      Timer.periodic(const Duration(seconds: 1), (timer) {
                        if (countdown == 0) {
                          timer.cancel();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ERGOne(
                                title: 'Begin ERGOne Workout',
                                threshold: threshold,
                                smoothAlpha: smoothAlpha,
                                currentSlider1: currentSlider1,
                                currentSlider2: currentSlider2,
                                currentSlider3: currentSlider3,
                              ),
                            ),
                          );
                        } else {
                          setState(() {
                            buttonText = countdown.toString();
                            countdown--;
                          });
                        }
                      });
                    }
                  /*    onPressed: (){// DELAY NAVIGATE TO 2ND SCREEN
                    // WIDGETS ARE IMMUTATBLE, CHANGE TEXT BY ARGUMENT
                    buttonText = 'Count Down'; // USE setState TO show count
                    // above does not work
                    // COUNTDOWN STOPWATCH METHOD HERE
                    Future.delayed(const Duration(seconds: 5), () {
                      if (!context.mounted) return;   //SAFETY
                      Navigator.push(context,
                      MaterialPageRoute(
                      // GO TO ERGOne screen after 5 seconds with these parameters
                        builder: (context) => ERGOne(
                        title: 'Begin ERGOne Workout',
                        threshold: threshold,
                        smoothAlpha: smoothAlpha,
                        currentSlider1: currentSlider1,
                        currentSlider2: currentSlider2,
                        currentSlider3: currentSlider3,
                           ),
                          ),
                        );
                      setState(() {
                        buttonText;   // change buttonText with countdown
                           });
                          });
                        }, */ //on pressed
                     ),
                  ),
      //-----------------------------------------------------------------
              // spacer
              SizedBox(
                height:10,
                width: 100,
              ),

     /*   // NEXT RM8 METHODS HERE-----------------------------------------
              // ANOTHER TAP BUTTON (go to Reports)
              SizedBox(
                height:60, //height of buttonA
                width:180, //width of button
                child:ElevatedButton(
                  style: style,
                  onPressed: () {Navigator.pushNamed(context,'/2nd');
                  },
                  child: const Text('Summary (tbd)'),
                    ),      // ELEVATED BUTTON
                  ),

       //----------------------------------------------------------------
              SizedBox(
                height:15,
                width: 100,
              ),
      */
        //---------------------------------------------------------------
           SizedBox(
                  height: 40,
                  width: 100,
                  child:
                  TextField(
                    controller: _thresholdcontroller,
                    keyboardType: const
                    TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      //isDense: true,
                      //contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                      labelText: 'Threshold',
                    ),
                    onChanged: (value) {
                      final double? parsed = double.tryParse(value);
                      if (parsed != null) {
                        setState(() {
                          threshold = double.tryParse(value) ?? 1.0;
                        });
                      }
                    },
                  ),
                 ),
//------------------------------------------------------------------------------
                  SizedBox(
                    height:15,
                    width: 100,
                  ),
//------------------------------------------------------------------------------
                  SizedBox(
                    height: 40,
                    width: 100,
                    child:
                    TextField(
                      controller: _smoothcontroller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(),
                        labelText: 'Smoother',
                      ),
                      onChanged: (value) {
                        final double? parsed = double.tryParse(value);
                        //final  parsed = num.tryParse(value);
                        if (parsed != null) {
                          // use threshold safely
                          setState(() {
                            smoothAlpha = double.tryParse(value) ?? 0.0;
                          });
                        }
                      },
                    ),
                  ),

     //-----------------------------------------------------------------------
                  SizedBox(
                    height:15,
                    width: 100,
                  ),

                // NOTE THAT "value" IS A PROPERTY OF THE TEXT ENTRY WIDGET !!
              ])])));
            }                     // HOME screen override BUILD widget
          }                       // RM8 Stateful Widget CLASS
//END OF RM8 STARTING Widget
//-------------------------------------------------------------------------------
// A CLASS OF FILTERS WITH PARAMETER ALPHA
class ExpSmoother {
  final double alpha;
  double? _last;
  ExpSmoother(this.alpha);
  // a smoother method
  double filter(double x) {
    if (_last == null) {
      _last = x;
    } else { _last = alpha * x + (1 - alpha) * _last!; }
    return _last!;
  }}

//------------------------------------------------------------------------------
class RollingStd {
  final int windowSize;
  final List<double> _buffer;
  int _index = 0;
  int _count = 0;
  double _sum = 0.0;
  double _sumSq = 0.0;
// A RollingStd class object
  RollingStd(this.windowSize)
      : _buffer = List.filled(windowSize, 0.0);
// Method
  void add(double x) {
    // Remove oldest value if buffer is full
    if (_count == windowSize) {
      final old = _buffer[_index];
      _sum -= old;
      _sumSq -= old * old;
    }
    else {
      _count++;
    // Add new value
    _buffer[_index] = x;
    _sum += x;
    _sumSq += x * x;
    _index = (_index + 1) % windowSize;
  }}
// Functions
  double get mean => _count == 0 ? 0.0 : _sum / _count;
  double get variance {
    if (_count == 0) return 0.0;
    final m = mean;
    return max(0.0, (_sumSq / _count) - m * m);
  }
  double get std => sqrt(variance);
}
//Usage: create a RollingStd class object name rm8Stats
// ------------------------------------------------------------------------------
class StrokeDetector {

  final double alpha = 0.1;     // low value limits baseline changes
  final double thresholdFactor = 1.6; // cgpt 1.4-2
  double prevThreshold = 1;    // starting value >0 needed
  double baseline = 0.0;
  double noise = 0.0;
  double energy = 0.0;
  double beta = 0.05;           // noise ema "speed" (.02-.05)

  double previousvalue =0.0;
  int lastStrokeTimeMs = 1;
  int strokeCount = 0;

  //double avgcadence =3;
  double xthreshold = 1.35;       // this shows on screen does not change !!
  double xcadence = 0;
  double xavgCadence = 1.0 ;
  int minStrokeGapMs = 1000;     // default value
  int strokeGap = 500;

  //-------------------------------------------------------------------------
  double tempBaseline(double value) {
    // EMA if not 0
    baseline = baseline == 0 ? value : (1 - alpha) * baseline + alpha * value;
    return baseline;   }
  //-------------------------------------------------------------------------
  double average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

 //---------------------------------------------------------------------------
  /* DYNAMIC THRESHOLD UPDATES ACCORDING TO LEVEL OF ACTIVITY. HIGHLY RECOMMENDED
   BY CGPT. Threshold values are incremented (or decremented according to
   signal level. Previously only called when INSTROKE NOT TRUE. REVISED NOW TO
   UPDATE BASELINE (WHEN NOT INSTROKE) EACH STREAMING SAMPLE. THEN CALL
   updateDynamicThreshold in STREAM AND PASS CURRENT BASELINE BY PARAMETER. */

    double updateBaseline (double value, double threshold){
      if ( value < 1.15 * threshold ) {
      // EMA if not 0 safety
      baseline = baseline == 0 ? value : (1 - alpha) * baseline + alpha * value;
        }
      return baseline;
      }
    double updateDynamicThreshold({
      required double currentValue,
      required double baseline,
      required double prevThreshold,
    double alpha = 0.1,    // adapt speed (slow = stable)
    double floor = .5,     // min threshold
    double ceiling = 5.0,  // max threshold
    double scale = 1.6,     // sensitivity factor
    double updated = 0.0,
          }) {
    final double deviation = (currentValue - baseline).abs();
    // Set target threshold (60pc above recent baseline signal level)
    final double target = deviation * scale;
    /* Exponential Moving Average (EMA) smooths threshold. If current sample
    is a "recovery" out of previous EMA a stroke is triggered according to
    EMA alpha (speed) value.  */
    double updated = (1 - alpha) * prevThreshold + alpha * target;
    prevThreshold = updated;
    // Clamp
    if (updated < floor) updated = floor;
    if (updated > ceiling) updated = ceiling;
    return updated; // THRESHOLD UPDATED
  }
//----------------------------------------------------------------------------
/* THE MAIN METHOD OF THE STROKEDETECTOR CLASS
13Feb(e) replaced _t on 30ms intervals with timestamped values trying to improve
 cadence calculation. lastTimestamp is initialized before streaming
 RUNS ONCE FOR EACH DETECTED STROKE */
/* 17Feb replaced DateTime stamps with stopwatch per cGPT */

  void detectStroke(double value, int sampleMs){
    /* The first lastStrokeTimeMs is initialized value. If (0) first
    recovery detection after mnStrokeGapMs counts as a stroke. */
    strokeGap = sampleMs - lastStrokeTimeMs;
    // TRUE PREVENTS DOUBLE STROKES
    bool pastGap = strokeGap > minStrokeGapMs;
    /* Crossing threshold with increasing value */
    bool crossedUp = previousvalue < threshold && value >= threshold;
    /* Conditions for a "recovery" detected. A recovery counts as a stroke */
    if (crossedUp && pastGap){
      strokeCount++;
      //print(strokeGap);
      lastStrokeTimeMs = sampleMs;
      strokeTimes.add(lastStrokeTimeMs);
      Vibration.vibrate(duration: 500); //thigh haptic
      // recovery-based cadence
      xcadence = 60000/strokeGap;
      liveCadence.add(xcadence);
      // setter?
      xavgCadence= average(liveCadence);
      }
    /* Reset previousvalue and return whether or not a stroke is counted !! */
    previousvalue = value;
    }
 // for avgCadence screen display
  double get avgCadence => xavgCadence;
  set avgCadence(double avgCadence) {
    avgCadence = avgCadence;}

 // GETTER METHODS => returns
    int get strokes => strokeCount;       // for rowing screen
    double get threshold => xthreshold;   // for rowing screen
    double get cadence => xcadence;       // for rowing screen
    }

    // END OF STROKE UPDATES (strokeStart TRUE)

//--------------------------------------------------------------------------
class ERGOne extends StatefulWidget {
  final String title;
  final double threshold;
  final double smoothAlpha;
  final double currentSlider1;
  final double currentSlider2;
  final double currentSlider3;
  const ERGOne({super.key,
    required this.title,
    required this.threshold,
    required this.smoothAlpha,
    required this.currentSlider1,
    required this.currentSlider2,
    required this.currentSlider3,
    });
// CREATE A STATE OBJECT FOR the ERGOne screen
  @override
  State<ERGOne> createState() => _ERGOneState();  }
//============================================================================
  //int peakFlag = 0;
  int nPeaks = 0;
  double newvalue = 0.0;
  double mtrsRowed = 0.0;
  String repavgCadence = '0';
//-----------------------------------------------------------------------------
class _ERGOneState extends State<ERGOne> {
  // MAINTAIN A ROLLING LIST OF SMOOTHED POINTS
  // Are these objects are shared by all functions and methods below ?
  final smoother = ExpSmoother(smoothAlpha);
  final int maxPoints = 200;
  List<FlSpot> spots = [];
  List<FlSpot> dataSet1 = [];
  List<FlSpot> dataSet2 = [];
  //List<double> liveCadence = [];

  double xavgCadence = 1;
  //double xminPer500 = 1;
  double? smthSec;
  double rm8Mean = 0;
  double rm8Std = 0;
  double lastValue = 0.0;
  double cadence = 10;
  double alphaCad = 0.2;
  double _t = 0;  // throttle stream time (milliseconds)
  int streamT =0;
  double minStrokeGapMs = 1000;
  double threshold = 1.0;
  double baseline = 1.0;

  // SUBSCRIBE/STORE THE STREAM AND SAVE TO REFERENCE
  //DateTime lastTimestamp = DateTime.now();   // IMPORTANT: an _ERGOneState object
  StreamSubscription<UserAccelerometerEvent>? accelSub;
  // INITIALIZE
  final Stopwatch streamTime = Stopwatch();
//-----------------------------------------------------------------------------
  @override
  void initState() {
    _t = 0; // start of streaming time (ms??)
    // target cadence-based delay interval
    minStrokeGapMs =  30000/_currentSlider3Value;   // half target stroke (ms)
    //maxCadence = 1.5 * _currentSlider3Value;      // upper limit above target
    super.initState();
    Vibration.vibrate(duration: 1000); //OK
    // BEGIN STREAMING
    // get milliseconds since epoch and used as starting time

    accelSub = userAccelerometerEventStream().listen(_onAccel);


  }

//_ERGOneState methods---------------------------------------------------------
  @override
  void dispose() {
    accelSub?.cancel();
    super.dispose();
  }
  void stopStreaming() {
    accelSub?.cancel();
    accelSub = null;
    dispose(); }


  // RollingStd rm8Stats = RollingStd(10); NOT USED FOR NOW
  // CREATE THE detector INSTANCE
  StrokeDetector detector = StrokeDetector(); // a StokeDetector object
  double average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /*
  double average(List<num> values) {
    if (values.isEmpty) return 0;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;  }

*/



// for graph onl----------------------------------------------------------------
    void addData(double x, double y1) {
    setState(() {
      dataSet1.add(FlSpot(x, y1));
      //   dataSet2.add(FlSpot(x, y2));
      // Optional: keep only the last 20 points
      if (dataSet1.length > 20) {
        dataSet1.removeAt(0);
          }
        });
      }
//------------------------------------------------------------------------------
   void buildUser() {
       user.add({
         'Name': 'Jim',
         'Piece Length': _currentSlider1Value,
         'Meters Rowed': mtrsRowed,
         'Mtrs/Stroke': _currentSlider2Value,
         'Piece Time': xpieceTimemin,
         'Min/500': pieceTimemin * (mtrsRowed / 500),
         '#strokes': nPeaks,
         'AvgCadence': avgCadence,
         'TargetCadence': _currentSlider3Value,
       });
     }
//------------------------------------------------------------------------------
  void buildRows() {
    /* ONLY FIRST ROW IN rows BUILT !!!  BECAUSE ONLY CALLED ONCE! look at
    strokeTimes length*/
    rows.clear();
    for (int i = 0; i < strokeTimes.length && i < liveCadence.length; i++) {
      rows.add({
        'time': strokeTimes[i],
        'cadence': liveCadence[i],
      });
    }
  }

//--------------------------------------------------------------------------
  void _onAccel(UserAccelerometerEvent e) {
    streamTime.start();                     // RUNS UNTIL STOPPED
    /* _t is local streaming time */
    _t += 30; // THROTTLE accel VALUES (accel stream is free running)
    final value = e.y ;
    // EXPONENTIAL SMOOTH raw Y-AXIS ACCELL !!
    double smoothValue = smoother.filter(value);
    // DETECTOR RUNS EVERY VALUE !! MUST LIMIT TO ONLY DETECTED STROKES
    streamT = streamTime.elapsedMilliseconds;
    baseline = detector.updateBaseline(smoothValue,threshold);
    detector.updateDynamicThreshold(currentValue:smoothValue, baseline: baseline,
        prevThreshold:threshold);

    detector.detectStroke(smoothValue,streamT);     // detectStroke is a method !!
    cadence = detector.cadence;                // for display
    cadence = double.parse(cadence.toStringAsFixed(2));
    threshold = detector.threshold;             // threshold GETTER
    threshold = double.parse(threshold.toStringAsFixed(2));
    nPeaks = detector.strokes;                  // nPeaks GETTER !!
    mtrsRowed = nPeaks *_currentSlider2Value;
    // DETECTOR METHOD CREATES LISTS AT STROKE TIMES TO EXPORT
    // CHART UPDATES
    addData(_t, value); //60 pt limit
    // PIECE ENDS------------------------------------------------------
    if (mtrsRowed >= _currentSlider1Value) {
      accelSub?.cancel();
      accelSub = null;
      streamTime.stop();
      Vibration.vibrate(duration: 1000); //end of piece
      //strokeTimes are int mS
      // THESE ARE ALL END OF PIECE REPORT VALUES
      pieceTimemin = streamT/60000;  // initially 0 elapsedMs
      minPer500 = 500*pieceTimemin/mtrsRowed;
      xavgCadence = (detector.avgCadence); // need this
      repavgCadence = xavgCadence.toStringAsFixed(1);
      xpieceTimemin =double.parse(pieceTimemin.toStringAsFixed(2));
      xminPer500 = double.parse(minPer500.toStringAsFixed(2));
      // at end of a piece build these lists
      buildRows();  // build rows list from streaming (time, liveCadence) in detector
      buildUser();  // only build once here


      setState(() {avgCadence;           // LIVE
        threshold;                    // LIVE
        nPeaks;                       // LIVE
      });
      dispose();
     //for User map
      reportList[0] = _currentSlider1Value; //piece length
      reportList[1] = mtrsRowed; // rowedTime;
      reportList[2] = _currentSlider2Value; //mtrsPerstroke;
      reportList[3] = xpieceTimemin;  //total piece time
      reportList[4] = pieceTimemin*(mtrsRowed/500);  //minutes/500m
      reportList[5] = nPeaks; //# strokes
      reportList[6] = avgCadence;
      reportList[7] = _currentSlider3Value; //tgtCadence;
    }}

/* TRANSFER TO A CSV FILE FROM A LIST OF MAPPED STROKE TIMES, CADENCE, ETC
   PERHAPS ADD OTHER DERIVED CALCULATIONS TO ADD MORE TO RM8lITE SPREADS
*/

// END OF _onAccel METHOD IN _ERGOneState --------------------------------------
  @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stroke Count')),
      // BEGIN A LIST OF CHILDREN WIDGETS [ ] !!
        body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            // 1ST COLUMN  CHILD OF THIS ROW
            Column(children: <Widget>[
          // 3. LINE CHART 1 (accels AND live cadence)------------------------------------------
              // look for FLSpot in streaming section (line 489 for chatGPT solution)
             SizedBox(
                width: 360,
                height: 140,
                child: LineChart(
                  LineChartData(
                    //ONLY ONE HORIZONTAL AXIS (axis modified to  seconds)
                    minX: dataSet1.isEmpty ? 0 : (dataSet1.first.x),
                    maxX: dataSet1.isEmpty ? 20 : (dataSet1.last.x),
                    minY: -4,
                    maxY: 4,
                    lineBarsData: [
                      LineChartBarData(
                        spots: dataSet1, // List<FlSpot>
                        isCurved: true,
                        color: Colors.blue,
                        ),
                    LineChartBarData(
                        spots: dataSet2,
                        isCurved: true,
                        color: Colors.red,
                        ),
                      ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1000, // 👈 division every 1 second
                          getTitlesWidget: (value, meta) {
                            final seconds = value ~/ 1000;
                            return Text(
                              '$seconds s',
                              style: const TextStyle(fontSize: 12),
                                  );
                                },
                              ),
                          ),)
                        ),
                      ),
                    ),
         // spacer
              SizedBox(
                height:20,
                width: 100,
              ),


         // STROKE COUNT----------------------------------------------------
              SizedBox(
                height:40, //height of button
                width:180, //width of button
                child: Text('#STOKES $nPeaks',
                    //style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center
                ),    // TEXT
              ),
          // spacer
              SizedBox(
                height:10,
                width: 100,
              ),
              SizedBox(
                height:40, //height of button
                width:180, //width of button
                child: Text('Live Cadence: $cadence',
                    //style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center
                ),    // TEXT
              ),
     /*         SizedBox(
                height:40, //height of button
                width:180, //width of button
                child: Text('Target Cadence: $_currentSlider3Value',
                    //style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center
                ),    // TEXT
              ),

      */
              // DISTANCE ROWED-------------------------------------------------
              // REPPLACE WITH MTRS TO GO
              SizedBox(
                height:40, //height of button
                width:180, //width of button
                child: Text('Rowed(mtrs): $mtrsRowed',
                    //style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center
                ),    // TEXT
              ),
  //----------------------------------------------------------------------------
              SizedBox(
                height:40,
                width: 100,
              ),
              SizedBox(
                height:40, //height of button
                width:180, //width of button
                child: Text('Threshold: $threshold',
                    //style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center
                ),    // TEXT
              ),
    //-------------------------------------------------------------------------
              SizedBox(
                height:20,
                width: 100,
              ),
              SizedBox(
                height:40, //height of button
                width:180, //width of button
                child: Text('Smooth Alpha: $smoothAlpha',
                    //style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center
                ),    // TEXT
              ),
    //------------------------------------------------------------------------
              SizedBox(
                height:10,
                width: 100,
              ),
  /* // PAUSE,STOP, OR RESTART--------------------------------------------------------------
              SizedBox(
                height: 40, //height of buttonA
                width: 89, //width of button
                child: ElevatedButton( // this is working
                  //style: style,
                  onPressed: () {
                    stopStreamingAndVibrate2();
                    //stopStreaming();
                    //accelSub?.cancel();
                    //accelSub = null;
                    //dispose();
                  },
                  child: const Text('Stop'),
                ),
              ),*/
  //---------------------------------------------------------------------------
              SizedBox(
                height:10,
                width: 100,
              ),
  // GO TO REPORT----------------------------------------------------------------
               SizedBox(
                height: 40, //height of buttonA
                width: 100, //width of button
                child: ElevatedButton(
                  //style: style,
                  onPressed: () {
                    Navigator.pushNamed(context,'/2nd'); // OK while streaming
                    },
                  child: const Text('Report'),
                ),
              ),
            ]
                )
              ])
            )
          );}}

//-----------------------------------------------------------------------------
/* OTHER LIVE SPM METHODS TO LOOK AT: ALL METHODS REQUIRE TIMESTAMP AT EACH
   STROKE DETECTED !!
   LIVE AS IF COX USING WATCH TO COUNT TIME FOR 5 STROKES AND COMPUTE SPM
   UPDATE EVERY 5 STROKES. chatGPT SUGGESTS AVERAGE OVER 10 STROKES
   (EVENTUALLY STABILIZES)
 */
//--------------------------------------------------------------------------
// REVIEW REPORTED VALUES !!
class Report extends StatefulWidget {
  final String title;
  const Report({super.key, required this.title});

  List<List<dynamic>> convertToCsv(List<Map<String, dynamic>> rows) {
    return [
      ['time', 'cadence'], // header row
      ...rows.map((row) => [
        row['time'],
        row['cadence'],
      ])
    ];
  }
  @override
  State<Report> createState() => _ReportState();
}
/*============================================================================
TEST EXPORT ROWS ONLY THEN SEPARATE USER EXPORT WITH COMMON IDENT IN FILENAMES
EXPORT USER PROFILE SEPARATELY (SEPARATE TAP) AND NAME FILES BY DATE!!
*/
class _ReportState extends State<Report> {
  // CREATE CSV FROM ROW DATA ONLY
  Future<void> toCSV(List<Map<String, dynamic>> rows) async {
    try {// convert maps to csv
      final csvData = convertToCsv(rows); //27Feb
      final csvRows= const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/data.csv';
      final file = File(path);
      await file.writeAsString(csvRows);
      //final exists = await file.exists();
      final length = await file.length();
      print('File size: $length bytes');
      // IN THE "SANDBOX" NOT EASILY AVAILABLE look to chatGPT to verify
      // SHARE ??
      print('CSV saved to: $path');
    } catch (e) {
      print('CSV error: $e');
    }
  }
  //-------------------------------------------------------
  // EXPORT CSV FROM "SANDBOX"
 /* Future<void> shareCsv(File file) async {
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My exported rowing session',
        ),
      );
    } else {
      print("File not found");
    }
  } */

  Future<void> exportExistingFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My exported rowing session',
        ),
      );
    } else {
      print("File not found");
    }
  }

    /*
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My exported rowing data',
      );
    } else {
      print("File not found");
    }
  }*/
  List<List<dynamic>> convertToCsv(List<Map<String, dynamic>> rows) {
    return [
      ['time', 'cadence'], // header row
      ...rows.map((row) => [
        row['time'],
        row['cadence'],
      ])
    ];
  }

//------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    ButtonStyle style =
    ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
    return Scaffold(
        appBar: AppBar(
          title: Text('Feb 2026'),
        ),
        body: Center(
            child: Row(
                children:<Widget>[
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                            height: 100,
                            width: 200,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text('RM8Lite Report',
                                style: Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center
                              ),    // TEXT
                            )
                        ),      // SIZED BOX
//---------------------------------------------------------------------------
                        SizedBox(
                          height:40,
                          width:200,
                          child: Text('Piece Length: $_currentSlider1Value ',
                            style: Theme.of(context).textTheme.bodyLarge,
                            //style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),    // TEXT
                        ),
                        //----------------------------------------------------------------
                        SizedBox(//#1
                          height:40,
                          width:200,
                          child: Text('Mtrs Rowed: $mtrsRowed',
                            style: Theme.of(context).textTheme.bodyLarge,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                          ),    // TEXT
                        ),
                        SizedBox(//#2
                          height:40,
                          width:200,
                          child: Text('Mtrs/Stroke: $_currentSlider2Value',
                            style: Theme.of(context).textTheme.bodyLarge,
                            //style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),    // TEXT
                        ),
                        SizedBox(//#3
                          height:40,
                          width:200,
                          child: Text('Time: $xpieceTimemin',
                            style: Theme.of(context).textTheme.bodyLarge,
                            //style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),    // TEXT
                        ),
                        SizedBox(//#4
                          height:40, //height of button
                          width:200,
                          child: Text('Minute/500m: $xminPer500',
                              style: Theme.of(context).textTheme.bodyLarge,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center
                          ),    // TEXT
                        ),
                        SizedBox(//#5
                          height:40, //height of button
                          width:200,
                          child: Text('#Strokes: $nPeaks',
                              style: Theme.of(context).textTheme.bodyLarge,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center
                          ),    // TEXT
                        ),
                        SizedBox(//#6
                          height:40, //height of button
                          width:200,
                          child: Text('Avg.Cadence: $repavgCadence',
                              style: Theme.of(context).textTheme.bodyLarge,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center
                          ),    // TEXT
                        ),
                       /* SizedBox(//#7
                          height:40, //height of button
                          width:200,
                          child: Text('Your Effort Level: $_currentSlider4Value',
                              style: Theme.of(context).textTheme.bodyLarge,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              //style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center
                          ),    // TEXT
                        ),
                        */
        //----------------------------------------------------------------------
                        // FIRST SLIDER (CHOOSE PIECE LENGTH)
                        Text(
                          'Your Perceived Effort: ${_currentSlider4Value.round()}',
                          style: const TextStyle(fontSize: 20),
                        ),
                        SizedBox( // TO SIZE SLIDER WIDGET
                          height: 40,
                          width:300,
                          child: Align(
                            alignment: Alignment.center,
                            child:
                            Slider(
                              value: _currentSlider4Value,
                              min: 60.0,
                              max: 110.0,
                              divisions: 5, // Optional: Creates 4 discrete intervals (0, 20, 40, 60, 80, 100)
                              label: _currentSlider4Value.round().toString(), // Label that pops up when dragging the thumb
                              onChanged: (double newValue) {
                                setState(() {
                                  _currentSlider4Value = newValue;
                                });
                              },
                            ),
                          ),    // TEXT
                        ),
                        //---------------------------------------------------------------
                        //----------------------------------------------------------------
                        SizedBox(
                          height:20,
                          width: 100,
                        ),
    //--------------------------------------------------------------------------
                        SizedBox(
                          height:80, //height of buttonA
                          width:180, //width of button
                          child:
                          ElevatedButton(
                            style: style,
                            onPressed: () async {
                              //buildCombined();
                              await toCSV(rows);
                              await exportExistingFile(
                                  "/data/user/0/com.example.rm8_1/app_flutter/data.csv"
                              );
                              if (context.mounted) {
                                Navigator.pushNamed(context, '/1st');
                                  }
                                },
                            child: const Text('Save Stroke'),
                            ),
                          ),
               SizedBox(
                          height:80, //height of buttonA
                          width:180, //width of button
                          child:
                          ElevatedButton(
                            style: style,
                            onPressed: () async {

                              if (context.mounted) {
                                Navigator.pushNamed(context, '/1st');
                              }
                            },
                            child: const Text('Save User Summary'),
                          ),
                        ),



                        //-------------------------------------------------------------------------
                      ])])));
  }                     // HOME screen override BUILD widget
}                       // RM8 Stateful Widget CLASS
//END OF REPORT Widget
