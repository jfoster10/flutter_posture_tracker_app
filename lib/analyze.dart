import 'dart:math';

class Analyze(List<List<dynamic>> inputData){

  // ROW LAYOUT: 0=Index 7=FullPitch 8=FullRoll 9=FullCurvature 10=Position(string)
  List<List<dynamic>> data = inputData;

  // ROW LAYOUT: 0=Length (of position) 1=Position 2=AvgLargest 3=AvgCurve 4=StdLargest 5=StdCurve 6=Significance 7=RelevantIndex
  List<List<dynamic>> posCounts = [];

  var entropyProportion = 0.0;
  var totalLength = inputData.length;

  // The two most significant posture states in this file (indexes to refer to them)
  int mostSignificant = 0;
  int secondMostSignificant = 0;


  Future<void> getPositionCounts() async {
    var streak = 1;
    var prevPos = data[0][10];
    var listData = [];

    var left = double.parse(data[0][0]);
    var right = left;

    try {
     for (List<dynamic> row in data){
      
      var largest = max(double.parse(row[7]).abs(), double.parse(row[8]).abs());
      var curve = double.parse(row[9]);
      var pos = row[10];


      if(posCounts.isNotEmpty && prevPos == pos){ // Did the position change?
        
        // Tracking for standard deviation
        print("no change");
        listData.add([largest, curve]);

        // If continued in the same position, accumulate measurements for averages
        posCounts.last[2] += largest;
        posCounts.last[3] += curve;
      }
      else{
        if(posCounts.isNotEmpty){
          print("change");
          posCounts.last[0] = streak;

          // Take averages
          posCounts.last[2] /= streak;
          posCounts.last[3] /= streak;
          print("Averages: ${posCounts.last[2]}, ${posCounts.last[3]}");

          // Take standard deviations
          if(listData.isNotEmpty){
            var stdDevLargest = 0.0;
            var stdDevCurve = 0.0;
            for(var cols in listData){
              stdDevLargest += pow((cols[0] - posCounts.last[2]), 2);
              stdDevCurve += pow((cols[1] - posCounts.last[3]), 2);
            }

            posCounts.last[4] = pow((stdDevLargest/streak), 0.5);
            posCounts.last[5] = pow((stdDevCurve/streak), 0.5);
            print("Standard Deviations: ${posCounts.last[4]}, ${posCounts.last[5]}");
            print("Position: ${posCounts.last[1]}");
            print("Window: $left, $right");
          }
        }

        // Reset streak
        streak = 1;
        listData = [[largest, curve]];
        left = right;

        // Initialize tracking for new position
        // streak, position, averages [largest, curve], standard deviations [largest, curve]
        posCounts.add([streak, pos, largest, curve, 0.0, 0.0]);
      }

      prevPos = pos;
      streak++;

      right++;
     }

     print("posCounts: $posCounts");
    } catch (e, stackTrace) {
      print("Computation error: $e");
      print("Stack Trace: $stackTrace");
    }
  }


  // ROW LAYOUT: 0=Length (of position) 1=Position 2=AvgLargest 3=AvgCurve 4=StdLargest 5=StdCurve 6=Significance 7=RelevantIndex
  Future<void> getPosSignificances() async{
    try{
      var index = 0;

      var entropy=0.0;

      for(List<dynamic> row in posCounts){
        // Significance value 
        var offset = row[0]*row[2];
        var curve = row[0]*row[3];
        row.add(offset+curve);

        // Relevant index
        var relevantIndex = (offset >= curve) ? 2 : 3;
        row.add(relevantIndex);
        print("Significance Row: $row");

        // Entropy
        double p = row[0]/totalLength;
        entropy -= p*(log(p)/log(2));

        // First and Second most significant position indexes
        if(row[6] >= posCounts[mostSignificant][6]){
          secondMostSignificant = mostSignificant;
          mostSignificant = index;
        }
        index++;
      }

      var numBlocks = posCounts.length;
      entropyProportion = entropy/(log(numBlocks)/log(2));
      print("Entropy Proportion: $entropyProportion");
      print("Most Significant: $mostSignificant");
      print("Second Most Significant: $secondMostSignificant");
    } catch (e, stackTrace) {
      print("Computation error: $e");
      print("Stack Trace: $stackTrace");
    }
  }

  int mostSignificantIndex(){
    return mostSignificant;
  }
  int secondMostSignificantIndex(){
    return secondMostSignificant;
  }

  String getSignificantPosition(int rowIndex){
    if(rowIndex < 0 || rowIndex > posCounts.length){
      return "Invalid index";
    }

    var pos = posCounts[rowIndex][1].replaceAll('_', ' ');
    var length = posCounts[rowIndex][0];
  
    if(rowIndex == mostSignificant){
      return "Your most signficant posture state was $pos, lasting $length samples (${(length/2).round()} seconds).";
    }
    else if(rowIndex == secondMostSignificant){
      return "You also remained in the $pos position for $length samples (${(length/2).round()} seconds).";
    }
    else{
      return "Irrelevant input";
    }
  }

  String getAverageDetails(int rowIndex){
    if(rowIndex < 0 || rowIndex > posCounts.length){
      return "Invalid index";
    }

    var offset = posCounts[rowIndex][2].round();
    var curve = posCounts[rowIndex][3].round();

    try{
      switch((offset, curve)){
        case( < 10, < 10):{
          return "You held a decent posture with average lean $offset° and curvature $curve°";
        }
        case( >= 10 && <= 20, < 10):{
          return "A noticeable average lean of $offset° was present with minimal curvature.";
        }
        case( > 20, < 10):{
          return "Although curvature was minimal, you had a significant average lean of $offset°.";
        }
        case( < 10, >= 10 && <= 20):{
          return "You were centered, but had a noticeable average curvature of $curve°.";
        }
        case( >= 10 && <= 20, >= 10 && <= 20):{
          return "You had a moderate average lean and curvature of $offset° and $curve° respectively.";
        }
        case( > 20, >= 10 && <= 20):{
          return "You had a highly significant lean of $offset°, as well as a noticeable curvature of $curve°.";
        }
        case( < 10, > 20):{
          return "You were centered, but had an unusually high spinal curvature of $curve°.";
        }
        case( >= 10 && <= 20, > 20):{
          return "You had a very high spinal curvature of $curve°, with a moderate lean of $offset° as well.";
        }
        case( > 20, > 20):{
          return "The position you maintained was highly abnormal, with an average lean of $offset° and a curvature of $curve°.";
        }
        default:{
          return "You had an average lean of $offset° and a curvature of $curve°.";
        }
      }
    }catch (e, stackTrace) {
      print("Computation error: $e");
      print("Stack Trace: $stackTrace");
      return("$e");
    }
  }

  String getVariationDetails(int rowIndex) {
    if(rowIndex < 0 || rowIndex > posCounts.length){
      return "Invalid index";
    }
    print("VARIATION ROW: ${posCounts[rowIndex]}");
    var stdLargest = posCounts[rowIndex][4].round();
    var stdCurve = posCounts[rowIndex][5].round();
    var std = max(stdLargest, stdCurve).round();
    var entropy = (entropyProportion*100).round();

    try{
      switch((std, entropyProportion)) {
        case(< 5, < 0.2):{
          return "Your position remained consistent with position entropy at only $entropy%. However, it's worth noting that remaining in a single position too long can result in static muscle fatigue, especially if that position is abnormal.";
        }
        case(< 5, >= 0.2 && <= 0.5):{
          return "You shifted positions at a rate of $entropy%. This is a reasonable place to be, as it gives your muscles time to readjust.";
        }
        case(< 5, > 0.5):{
          return "You shifted positions at a rate of $entropy%, indicating you moved around frequently. However, your most significant position had minimal variation ($std%).";
        }
        case(>= 5, < 0.2):{
          return "You rarely switched posture states at a rate of $entropy%, but within your significant posture state there was high deviation present ($std%). This can be an indicator of weak back muscles. If need be, it's perfectly fine to shift positions more often and give them a break.";
        }
        case(>= 5, >= 0.2 && <= 0.5):{
          return "You switched posture states at a decent rate of $entropy%, but within your significant posture state there was high deviation present ($std%). This is an indicator of weak back muscles.";
        }
        case(>= 5, > 0.5):{
          return "You shifted positions frequently at $entropy%, and your most significant position also had high variation ($std%). This indicates an unstable posture.";
        }
        default:{
          return "STD: $std%, Position Entropy: $entropy";
        }
      }
    }
    catch (e, stackTrace) {
      print("Computation error: $e");
      print("Stack Trace: $stackTrace");
      return("$e");
    }
  }
}