float WINDOW_SCALE_SIZE = 1.0;
int MINIMUM_WORD_LENGTH = 5;
float STARTING_AXON_VARIABILITY = 1.0;
int TRAINS_PER_FRAME = 20;
PFont font;
Brain brain;
int MIDDLE_LAYER_NEURON_COUNT = 30;
String[] trainingData;
int SAMPLE_LENGTH = 10;
//int INPUTS_PER_CHAR = 61+1+1; //hero type and MMR and hero level
int INPUT_LAYER_HEIGHT = 13+61+2+1; //13+INPUTS_PER_CHAR*SAMPLE_LENGTH+1;
int OUTPUT_LAYER_HEIGHT = 2+1;
int lineAt = 0;
int iteration = 0;
int guessWindow = 1000;
boolean[] recentGuesses = new boolean[guessWindow];
int recentRightCount = 0;
boolean training = false;
String word = "-";
int desiredOutput = 0;
int lastPressedKey = -1;
boolean typing = false;
boolean lastOneWasCorrect = false;
String[] languages = {"Team1win","Team2win"};
int clickY = -1;
int clickX = 0;
void setup(){
  trainingData = loadStrings("o.txt");
  for(int i = 0; i < guessWindow; i++){
    recentGuesses[i] = false;
  }
  font = loadFont("Helvetica-Bold-96.vlw"); 
  int[] bls = {INPUT_LAYER_HEIGHT,MIDDLE_LAYER_NEURON_COUNT,OUTPUT_LAYER_HEIGHT};
  brain = new Brain(bls,languages);
  size((int)(1920*WINDOW_SCALE_SIZE),(int)(1080*WINDOW_SCALE_SIZE));
  frameRate(200);
  train();
}

void draw(){
  if(clickY == 0){
    if(mouseX/30 > clickX/30){ // increase map
      double placeholder = brain.neurons[0][12];
      for(int i = 12; i >= 1; i--){
        brain.neurons[0][i] = brain.neurons[0][i-1];
      }
      brain.neurons[0][0] = placeholder;
    }else if(mouseX/30 < clickX/30){ // decrease map
      double placeholder = brain.neurons[0][0];
      for(int i = 0; i < 12; i++){
        brain.neurons[0][i] = brain.neurons[0][i+1];
      }
      brain.neurons[0][12] = placeholder;
    }
    clickX = mouseX;
  }
  if(clickY >= 1 && clickY < INPUT_LAYER_HEIGHT-1){
    float change = mouseX-clickX;
    brain.neurons[0][clickY+12] += change*0.004;
    clickX = mouseX;
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
    }else if(c == 52 && lastPressedKey != 52){
      brain.alpha *= 2;
    }else if(c == 51 && lastPressedKey != 51){
      brain.alpha *= 0.5;
    }else if(c >= 97 && c <= 122 && !(lastPressedKey >= 97 && lastPressedKey <= 122)){
      training = false;
      if(!typing){
        word = "";
      }
      typing = true;
      word = (word+(char)(c)).toUpperCase();
      getBrainErrorFromLine(word,0,false);
    }else if(c == 8 && lastPressedKey != 8){
      training = false;
      if(typing && word.length() >= 1){
        word = word.substring(0,word.length()-1);
      }
      typing = true;
      getBrainErrorFromLine(word,0,false);
    }
    lastPressedKey = c;
  }else{
    lastPressedKey = -1;
  }
  if(training){
    for(int i = 0; i < TRAINS_PER_FRAME; i++){
      train();
    }
  }
  background(255);
  fill(0);
  textFont(font,48);
  textAlign(LEFT);
  text("HOTSNN",20,50);
  text("Iteration #"+iteration,20,150);
  text("Input word:",20,250);
  fill(0,0,255);
  text(word.toUpperCase(),20,300);
  fill(0);
  text("Expected output:",20,350);
  String o = languages[desiredOutput];
  if(typing){
    o = "???";
  }
  fill(0,0,255);
  text(o,20,400);
  fill(0);
  text("Step size:",20,500);
  text(nf((float)(brain.alpha),0,4),20,550);
  
  textFont(font,20);
  text("Click input bubble and",20,700);
  text("drag left/right to change",20,720);
  
  text("-1 means Hero is on Team 1,",20,760);
  text("1 means Hero is on Team 2,",20,780);
  text("and 0 means Hero isn't on any team.",20,800);
  textFont(font,48);
  int ex = 1330;
  text("Actual prediction:",ex,50);
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
  text(languages[brain.topOutput]+" ("+s+")",ex,100);
  fill(0);
  
  text("Confidence: "+percentify(brain.confidence),ex,150);
  
  text("% of last "+guessWindow+" correct:",ex,250);
  text(percentify(((float)recentRightCount)/min(iteration,guessWindow)),ex,300);
  
  text("1 to toggle training.",ex,400);
  text("2 to do one training.",ex,450);
  text("3 to decrease step size.",ex,500);
  text("4 to increase step size.",ex,550);
  
  translate(550,40);
  brain.drawBrain(16);
  lineAt++;
}
void mousePressed(){
  if(round((mouseX-550.0)/16) == 0){
    clickY = round((mouseY-40.0)/16);
    clickX = mouseX;
  }else{
    clickY = -1;
  }
}
void mouseReleased(){
  if(clickY >= 1 && clickY <= 61){
    brain.neurons[0][clickY+12] = Math.round(brain.neurons[0][clickY+12]);
  }
  clickY = -1;
  brain.useBrainGetError(null, null,false,false);
}
void train(){
  int choiceLine = (int)(random(0,trainingData.length));
  String[] parts = trainingData[choiceLine].split(" ");
  desiredOutput = Integer.parseInt(parts[1]);
  double error = getBrainErrorFromLine(parts[0],desiredOutput,true);
  if(brain.topOutput == desiredOutput){
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
String percentify(double d){
  return nf((float)(d*100),0,2)+"%";
}
double getBrainErrorFromLine(String word, int desiredOutput, boolean train){
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
    //inputs[13+i*INPUTS_PER_CHAR+heroID] = 1;
    //inputs[13+i*INPUTS_PER_CHAR+61] = heroLevel*0.01;
    //inputs[13+i*INPUTS_PER_CHAR+62] = MMR*0.0001;
  }
  inputs[13+61] = totalMMRs[0]/5.0/1000.0;
  inputs[13+61+1] = totalMMRs[1]/5.0/1000.0;
  double desiredOutputs[] = new double[OUTPUT_LAYER_HEIGHT];
  desiredOutputs[0] = 1-desiredOutput;
  desiredOutputs[1] = desiredOutput;
  desiredOutputs[2] = 0;
  if(train){
    iteration++;
  }
  return brain.useBrainGetError(inputs, desiredOutputs,train,true);
}
int getIntAt(String word, int index){
  return (int)word.charAt(index)-33;
}
