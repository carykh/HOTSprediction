class Brain {
  double[][] neurons;
  double[][][] axons;
  int[] BRAIN_LAYER_SIZES;
  int MAX_HEIGHT;
  boolean condenseLayerOne = true;
  int drawWidth = 5;
  double alpha;
  int topOutput = 0;
  double confidence = 0.0;
  String[] outputs;
  Brain(int[] bls, String[] o, String[] fileData, double inputAlpha){
    outputs = o;
    BRAIN_LAYER_SIZES = bls;
    neurons = new double[BRAIN_LAYER_SIZES.length][];
    axons = new double[BRAIN_LAYER_SIZES.length-1][][];
    MAX_HEIGHT = 0;
    int lineProgress = 3;
    for(int x = 0; x < BRAIN_LAYER_SIZES.length; x++){
      if(BRAIN_LAYER_SIZES[x] > MAX_HEIGHT){
        MAX_HEIGHT = BRAIN_LAYER_SIZES[x];
      }
      neurons[x] = new double[BRAIN_LAYER_SIZES[x]];
      for(int y = 0; y < BRAIN_LAYER_SIZES[x]; y++){
        if(y == BRAIN_LAYER_SIZES[x]-1){
          neurons[x][y] = 1;
        }else{
          neurons[x][y] = 0;
        }
      }
      if(x < BRAIN_LAYER_SIZES.length-1){
        axons[x] = new double[BRAIN_LAYER_SIZES[x]][];
        for(int y = 0; y < BRAIN_LAYER_SIZES[x]; y++){
          axons[x][y] = new double[BRAIN_LAYER_SIZES[x+1]-1];
          for(int z = 0; z < BRAIN_LAYER_SIZES[x+1]-1; z++){
            if(fileData != null){
              axons[x][y][z] = Double.parseDouble(fileData[lineProgress]);
              lineProgress++;
            }else{
              double startingWeight = (Math.random()*2-1)*STARTING_AXON_VARIABILITY;
              axons[x][y][z] = startingWeight;
            }
          }
        }
      }
    }
    alpha = inputAlpha;
  }
  public double useBrainGetError(double desiredOutputs[], boolean mutate, boolean useInputs){
    int[] nonzero = {BRAIN_LAYER_SIZES[0]-1};
    for(int i = 0; i < BRAIN_LAYER_SIZES[0]; i++){
      if (neurons[0][i] != 0){
        nonzero = append(nonzero, i);
      }
    }
    for(int x = 0; x < BRAIN_LAYER_SIZES.length; x++){
      neurons[x][BRAIN_LAYER_SIZES[x]-1] = 1.0;
    }
    for(int x = 1; x < BRAIN_LAYER_SIZES.length; x++){
      for(int y = 0; y < BRAIN_LAYER_SIZES[x]-1; y++){
        float total = 0;
        if (x == 1) {
          for(int i = 0; i < nonzero.length; i++){
            total += neurons[x-1][nonzero[i]]*axons[x-1][nonzero[i]][y];
          }
        }
        else{
          for(int input = 0; input < BRAIN_LAYER_SIZES[x-1]-1; input++){
            total += neurons[x-1][input]*axons[x-1][input][y];
          }
        }
        neurons[x][y] = sigmoid(total);
      }
    }
    if(mutate){
      for(int y = 0; y < nonzero.length; y++){
        for(int z = 0; z < BRAIN_LAYER_SIZES[1]-1; z++){
          double delta = 0;
          for(int n = 0; n < BRAIN_LAYER_SIZES[2]-1; n++){
            delta += 2*(neurons[2][n]-desiredOutputs[n])*neurons[2][n]*
            (1-neurons[2][n])*axons[1][z][n]*neurons[1][z]*(1-neurons[1][z])*neurons[0][nonzero[y]]*alpha;
          }
          axons[0][nonzero[y]][z] -= delta;
        }
      }
      
      for(int y = 0; y < BRAIN_LAYER_SIZES[1]; y++){
        for(int z = 0; z < BRAIN_LAYER_SIZES[2]-1; z++){
          double delta = 2*(neurons[2][z]-desiredOutputs[z])*neurons[2][z]*
          (1-neurons[2][z])*neurons[1][y]*alpha;
          axons[1][y][z] -= delta;
        }
      }
      /*for(int y = 0; y < nonzero.length; y++){ // make the hero ID synapses not count.
        for(int z = 0; z < BRAIN_LAYER_SIZES[1]-1; z++){
          if(nonzero[y] >= 13 && nonzero[y] < 61){
            axons[0][nonzero[y]][z] = 0.0;
          }
        }
      }*/
    }
    topOutput = getTopOutput();
    if(!useInputs){
      return 0;
    }else{
      double totalError = 0;
      int end = BRAIN_LAYER_SIZES.length-1;
      for(int i = 0; i < BRAIN_LAYER_SIZES[end]-1; i++){
        totalError += Math.pow(neurons[end][i]-desiredOutputs[i],2);
      }
      return totalError/(BRAIN_LAYER_SIZES[end]-1);
    }
  }
  public int getTopOutput(){
    double record = -1;
    int recordHolder = -1;
    int end = BRAIN_LAYER_SIZES.length-1;
    for(int i = 0; i < BRAIN_LAYER_SIZES[end]-1; i++){
      if(neurons[end][i] > record){
        record = neurons[end][i];
        recordHolder = i;
      }
    }
    confidence = record;
    return recordHolder;
  }
  public double sigmoid(double input){
    return 1.0/(1.0+Math.pow(2.71828182846,-input));
  }
  public void drawBrain(float scaleUp, String[] heroStats){
    String[] parts = heroStats[0].split(",");
    String[] col = {"Blue","Red"};
    final float neuronSize = 0.4;
    noStroke();
    fill(128);
    rect(-0.5*scaleUp,-0.5*scaleUp,(1+(BRAIN_LAYER_SIZES.length-1)*drawWidth)*scaleUp,MAX_HEIGHT*scaleUp);
    ellipseMode(RADIUS);
    strokeWeight(3);
    textAlign(CENTER);
    textFont(font,0.58*scaleUp);
    for(int x = 0; x < BRAIN_LAYER_SIZES.length-1; x++){
      for(int y = 0; y < BRAIN_LAYER_SIZES[x]; y++){
        for(int z = 0; z < BRAIN_LAYER_SIZES[x+1]-1; z++){
          drawAxon(x,y,x+1,z,scaleUp);
        }
      }
    }
    int startPosition = 0;
    if(condenseLayerOne){
      for(int y = 0; y < BRAIN_LAYER_SIZES[0]; y++){
        int ay = apY(0,y);
        if(neurons[0][y] >= 0.5 || ay >= 1){
          double val = neurons[0][y];
          noStroke();
          fill(255);
          ellipse(0,ay*scaleUp,neuronSize*scaleUp,neuronSize*scaleUp);
          fill(0);
          String s = "IN";
          if(ay == 19){
            fill(255);
            ellipse(0,ay*scaleUp,neuronSize*scaleUp,neuronSize*scaleUp);
            fill(0);
            text("1",0,(ay+(neuronSize*0.55))*scaleUp);
          }else if(ay >= 1){
            fill(neuronFillColor(val));
            ellipse(0,ay*scaleUp,neuronSize*scaleUp,neuronSize*scaleUp);
            fill(neuronTextColor(val));
            text(nf((float)(val),0,1),0,(ay+(neuronSize*0.55))*scaleUp);
            fill(0);
            textAlign(RIGHT);
            text(col[(ay-1)/9]+" avg "+parts[(ay-1)%9+2],-0.7*scaleUp,(ay+(neuronSize*0.55))*scaleUp);
            textAlign(CENTER);
          }else{
            fill(255);
            ellipse(0,ay*scaleUp,neuronSize*scaleUp,neuronSize*scaleUp);
            fill(0);
            text("IN",0,(ay+(neuronSize*0.55))*scaleUp);
          }
        }
      }
      startPosition = 1;
    }
    for(int x = startPosition; x < BRAIN_LAYER_SIZES.length; x++){
      for(int y = 0; y < BRAIN_LAYER_SIZES[x]; y++){
        noStroke();
        double val = neurons[x][y];
        fill(neuronFillColor(val));
        ellipse(x*drawWidth*scaleUp,apY(x,y)*scaleUp,neuronSize*scaleUp,neuronSize*scaleUp);
        fill(neuronTextColor(val));
        text(coolify(val),x*drawWidth*scaleUp,(apY(x,y)+(neuronSize*0.52))*scaleUp);
        fill(0);
        if(y < 2 && x == 2){
          textAlign(LEFT);
          text(outputs[y],(0.7+x*drawWidth)*scaleUp,(y+(neuronSize*0.55))*scaleUp);
          textAlign(CENTER);
        }
      }
    }
  }
  public String coolify(double val){
    int v = (int)(Math.round(val*100));
    if(v == 100){
      return "1";
    }else if(v < 10){
      return ".0"+v;
    }else{
      return "."+v;
    }
  }
  public void drawAxon(int x1, int y1, int x2, int y2, float scaleUp){
    double v = axons[x1][y1][y2]*neurons[x1][y1];
    if(Math.abs(v) >= 0.001 && (x1 >= 1 || y1 < 13/* || y1 >= 13+61+2*/)){
      stroke(axonStrokeColor(axons[x1][y1][y2]));
      line(x1*drawWidth*scaleUp,apY(x1, y1)*scaleUp,x2*drawWidth*scaleUp,apY(x2, y2)*scaleUp);
    }
  }
  public int apY(int x, int y){
    if(condenseLayerOne && x == 0){
      return max(0,y-(13+61+2)+1);
    }else{
      return y;
    }
  }
  public color axonStrokeColor(double d){
    if(d >= 0){
      return color(255,255,255,(float)(d*255));
    }else{
      return color(1,1,1,abs((float)(d*255)));
    }
  }
  public color neuronFillColor(double d){
    return color((float)(d*255),(float)(d*255),(float)(d*255));
  }
  public color neuronTextColor(double d){
    if(d >= 0.5){
      return color(0,0,0);
    }else{
      return color(255,255,255);
    }
  }
  String brainToString(){
    String result = INPUT_LAYER_HEIGHT+","+MIDDLE_LAYER_NEURON_COUNT+","+OUTPUT_LAYER_HEIGHT+","+alpha;
    for(int x = 0; x < BRAIN_LAYER_SIZES.length-1; x++){
      for(int y = 0; y < BRAIN_LAYER_SIZES[x]; y++){
        for(int z = 0; z < BRAIN_LAYER_SIZES[x+1]-1; z++){
          result = result+"\n"+axons[x][y][z];
        }
      }
    }
    return result;
  }
}
