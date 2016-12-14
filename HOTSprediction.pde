float WINDOW_SCALE_SIZE = 1.0;
int MINIMUM_WORD_LENGTH = 5;
float STARTING_AXON_VARIABILITY = 1.0;
int TRAINS_PER_FRAME = 5000;
PFont font;
Brain brain;
int MIDDLE_LAYER_NEURON_COUNT = 70;
String[] trainingData;
int SAMPLE_LENGTH = 10;
//int INPUTS_PER_CHAR = 61+1+1; //hero type and MMR and hero level
int INPUT_LAYER_HEIGHT = 13+61+2+1; //13+INPUTS_PER_CHAR*SAMPLE_LENGTH+1;
int OUTPUT_LAYER_HEIGHT = 2;
int lineAt = 0;
int iteration = 0;
int guessWindow = 10000;
boolean[] recentGuesses = new boolean[guessWindow];
int recentRightCount = 0;
boolean training = false;
String word = "-";
int desiredOutput = 0;
int lastPressedKey = -1;
boolean typing = false;
boolean lastOneWasCorrect = false;
int clickSquare = -1;
int BRAIN_DRAW_SIZE = 35;
String[] heroNames = 
{"Unknown","Abathur","Anub'arak","Arthas","Azmodan","Brightwing","Chen","Diablo","E.T.C.","Falstad","Gazlowe","Illidan","Jaina","Johanna","Kael'thas","Kerrigan","Kharazim","Leoric","Li Li","Malfurion","Muradin","Murky","Nazeebo","Nova","Raynor","Rehgar","Sgt. Hammer","Sonya","Stitches","Sylvanas","Tassadar","The Butcher","The Lost Vikings","Thrall","Tychus","Tyrael","Tyrande","Uther","Valla","Zagara","Zeratul","Rexxar","Lt. Morales","Artanis","Cho","Gall","Lunara","Greymane","Li-Ming","Xul","Dehaka","Tracer","Chromie","Medivh","Gul'dan","Auriel","Alarak","Zarya","Samuro","Varian","Ragnaros"};
String[] mapNames = 
{"Battlefield of Eternity","Blackheart's Bay","Cursed Hollow","Dragon Shire","Garden of Terror","Haunted Mines","Infernal Shrines","Sky Temple","Tomb of the Spider Queen","Towers of Doom","Lost Cavern","Braxis Holdout","Warhead Junction"};
String[] outputs = {"Team blue wins","Team red wins"};
void setup(){
  trainingData = loadStrings("heroLeagueOnlyData.txt");
  for(int i = 0; i < guessWindow; i++){
    recentGuesses[i] = false;
  }
  font = loadFont("Helvetica-Bold-96.vlw"); 
  int[] bls = {INPUT_LAYER_HEIGHT,MIDDLE_LAYER_NEURON_COUNT,OUTPUT_LAYER_HEIGHT};
  brain = new Brain(bls);
  size((int)(1920*WINDOW_SCALE_SIZE),(int)(1080*WINDOW_SCALE_SIZE));
  frameRate(200);
  train();
}

void draw(){
  if(clickSquare >= 0){
    int nextCS = getClickSquare();
    if(clickSquare != nextCS){
      if(nextCS >= 15 && nextCS < 15+61 && 
      clickSquare >= 15 && clickSquare < 15+61){
        double ph = brain.neurons[0][clickSquare-2];
        brain.neurons[0][clickSquare-2] = brain.neurons[0][nextCS-2];
        brain.neurons[0][nextCS-2] = ph;
        updateBrainWithManualInput();
      }
    }
    if(clickSquare >= 80 && clickSquare < 85){
      brain.neurons[0][13+61] = min(max((mouseX-5)/630.0,0),1);
      updateBrainWithManualInput();
    }else if(clickSquare >= 85 && clickSquare < 95){
      brain.neurons[0][13+61+1] = min(max((mouseX-5)/630.0,0),1);
      updateBrainWithManualInput();
    }
    clickSquare = nextCS;
    setClickMap();
  }
  scale(WINDOW_SCALE_SIZE);
  if(keyPressed){
    int c = (int)(key);
    if(c == 49 && lastPressedKey != 49){
      training = !training;
      typing = false;
    }else if(c == 50 && lastPressedKey != 50){
      training = false;
      typing = false;
      train();
      //brain.useBrainGetError(null, null,false,false); // to make the input run on the newest set of synapses
  }else if(c == 52 && lastPressedKey != 52){
      brain.alpha *= 2;
    }else if(c == 51 && lastPressedKey != 51){
      brain.alpha *= 0.5;
    }
    lastPressedKey = c;
  }else{
    lastPressedKey = -1;
  }
  if(training){
    for(int i = 0; i < TRAINS_PER_FRAME; i++){
      train();
    }
    //brain.useBrainGetError(null, null,false,false); // to make the input run on the newest set of synapses
  }
  background(255);
  
  int ex = 5;
  
  fill(0);
  textFont(font,33);
  textAlign(LEFT);
  text("Heroes of the Storm Neural Net",ex,33);
  text("Question: What is Team Blue's",ex,66);
  text("chance of winning?",ex,100);
  
  text("Iteration #"+iteration,ex,133);
  //text("Input word:",20,236);
  //fill(0,0,255);
  //text(word.toUpperCase(),20,272);
  text("Click & drag to change team heroes.",ex,1000);
  text("Expected output:",ex,1033);
  String o = percentify(desiredOutput,true);
  if(typing){
    o = "???";
  }
  fill(0,0,255);
  text(o,ex,1066);
  fill(0);
  
  noStroke();
  textAlign(CENTER);
  textFont(font,16);
  int mapType = getMapType();
  for(int y = 0; y < 16; y++){
    for(int x = 0; x < 5; x++){
      int index = x+y*5;
      fill(200);
      if(mapType == index){
        fill(255,170,0);
      }else if(index >= 15 && index < 15+61){
        double val = brain.neurons[0][index-2];
        if(val <= -0.5){
          fill(80,160,255);
        }else if(val >= 0.5){
          fill(255,128,128);
        }
      }else if(y < 3){
        fill(150,255,150);
      }
      rect(x*135+5,y*45+150,130,40);
      fill(0);
      String s = "";
      if(index < 13){
        s = mapNames[index];
      }else if(index >= 15 && index < 15+61){
        s = heroNames[index-15];
      }
      text(s,x*135+10,y*45+153,120,40);
    }
  }
  fill(128);
  rect(5,870,670,40);
  rect(5,915,670,40);
  fill(180);
  textFont(font,33);
  text("Team Blue Average MMR",5,877,670,40);
  text("Team Red Average MMR",5,922,670,40);
  textFont(font,16);
  
  float x1 = (float)(5+630*(brain.neurons[0][61+13]));
  float x2 = (float)(5+630*(brain.neurons[0][61+13+1]));
  
  fill(80,160,255);
  rect(x1,870,40,40);
  fill(255,128,128);
  rect(x2,915,40,40);
  fill(0);
  text(""+Math.round(brain.neurons[0][61+13]*5000),x1+20,896);
  text(""+Math.round(brain.neurons[0][61+13+1]*5000),x2+20,941);
  
  textFont(font,33);
  textAlign(RIGHT);
  fill(0);
  ex = 1890;
  text("Actual prediction:",ex,33);
  String s = "";
  if(typing){
    s = "HOW'D I DO?";
    fill(160,120,0);
  }else{
    if(lastOneWasCorrect){
      s = "RIGHT";
      fill(0,140,0);
    }else{
      s = "WRONG";
      fill(255,0,0);
    }
  }
  text(percentify(brain.result, true)+" ("+s+")",ex,66);
  fill(0);
  
  text("% of last "+guessWindow+" correct:",ex,133);
  text(percentify(((float)recentRightCount)/min(iteration,guessWindow), false),ex,166);
  text("Step size:",ex,233);
  text(nf((float)(brain.alpha),0,4),ex,266);
  text("1 to toggle training.",ex,333);
  text("2 to do one training.",ex,366);
  text("3 to decrease step size.",ex,400);
  text("4 to increase step size.",ex,433);
  
  translate(800,40);
  brain.drawBrain(BRAIN_DRAW_SIZE);
  lineAt++;
}
void mousePressed(){
  clickSquare = getClickSquare();
  setClickMap();
}
void mouseReleased(){
  clickSquare = -1;
  brain.useBrainGetError(null, null,false,false);
}
void setClickMap(){
  if(clickSquare >= 0 && clickSquare < 13){
    for(int i = 0; i < 13; i++){
      if(i == clickSquare){
        brain.neurons[0][i] = 1;
      }else{
        brain.neurons[0][i] = 0;
      }
    }
    updateBrainWithManualInput();
  }
}
void updateBrainWithManualInput(){
  brain.useBrainGetError(null, null,false,false);
  typing = true;
}
int getMapType(){
  for(int i = 0; i < 13; i++){
    if(brain.neurons[0][i] >= 0.5){
      return i;
    }
  }
  return -1;
}
int getClickSquare(){
  int x = (mouseX-5)/135;
  int y = (mouseY-150)/45;
  if(x >= 0 && x < 5 && y >= 0 && y < 18){
    return x+y*5;
  }
  return -1;
}
void train(){
  int choiceLine = (int)(random(0,trainingData.length));
  String[] parts = trainingData[choiceLine].split(" ");
  desiredOutput = Double.parseDouble(parts[1]);
  word = parts[0];
  double error = getBrainErrorFromLine(word,desiredOutput,true);
  if((brain.result >= 0.50) == (desiredOutput >= 0.50)){
    if(!recentGuesses[iteration%guessWindow]){
      recentRightCount++;
    }
    recentGuesses[iteration%guessWindow] = true;
    lastOneWasCorrect = true;
  }else{
    if(recentGuesses[iteration%guessWindow]){
      recentRightCount--;
    }
    recentGuesses[iteration%guessWindow] = false;
    lastOneWasCorrect = false;
  }
}
String percentify(double d, boolean withTeam){
  String s = "";
  if(withTeam){
    if(d < 0.5){
      s = " (Team red wins)";
    }else{
      s = " (Team blue wins)";
    }
  }
  return nf((float)(d*100),0,2)+"%"+s;
}
double getBrainErrorFromLine(String word, double desiredOutput, boolean train){
  double inputs[] = new double[INPUT_LAYER_HEIGHT];
  for(int i = 0; i < INPUT_LAYER_HEIGHT; i++){
    inputs[i] = 0;
  }
  inputs[getIntAt(word,0)] = 1;
  int[] totalMMRs = {0,0};
  for(int i = 0; i < SAMPLE_LENGTH; i++){
    int heroID = getIntAt(word,1+i*4);
    int heroLevel = getIntAt(word,2+i*4);
    int MMR = getIntAt(word,3+i*4)*90+getIntAt(word,4+i*4);
    inputs[13+heroID] = -1+2*(i/5);
    totalMMRs[i/5] += MMR;
  }
  inputs[13+61] = totalMMRs[0]/5.0/5000.0;
  inputs[13+61+1] = totalMMRs[1]/5.0/5000.0;
  double desiredOutputs[] = new double[OUTPUT_LAYER_HEIGHT];
  desiredOutputs[0] = desiredOutput;
  desiredOutputs[1] = 0;
  if(train){
    iteration++;
  }
  return brain.useBrainGetError(inputs, desiredOutputs,train,true);
}
int getIntAt(String word, int index){
  return (int)word.charAt(index)-33;
}
