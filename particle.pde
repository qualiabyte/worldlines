public class Particle{

  Particle( PVector pos, PVector vel ){
    this.pos = pos;
    this.vel = vel;

    colorMode(RGB,255);
    setPathColor(color(0,200,200,180));

    //properTimeHist[0] = properTime;
    updateHist();
    updateHist();
  }

  void update(float dt){    
    pos.add(PVector.mult(vel, dt));
    pos.z += dt;
    properTime += dt / Relativity.gamma(vel);

    if((frameCount & 31) == 0) {
      //if (properTime - properTimeHist[histCount-1] > 20) {
      updateHist();
      /*
      posHist[histCount][0] = pos.x;
       posHist[histCount][1] = pos.y;
       posHist[histCount][2] = pos.z;
       
       properTimeHist[histCount] = properTime;
       
       histCount++;
       
       int a = (fillColor >> 24) & 0xFF;
       int r = ((fillColor >> 16)+16) & 0xFF;
       int g = ((fillColor >> 8)) & 0xFF;
       int b = (fillColor) & 0xFF;
       fillColor = (a<<24) + (r<<16) + (g<<8) + b;
       */
    }

  }

  void updateHist(){
    posHist[histCount][0] = pos.x;
    posHist[histCount][1] = pos.y;
    posHist[histCount][2] = pos.z;

    properTimeHist[histCount] = properTime;

    histCount++;
  }

  void draw(){
    drawHead();
    drawPathGL();
  }

  void drawHead(){
    float heading = atan2(vel.y, vel.x)-PI/2;

    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotate(heading);

    stroke(STROKE_WIDTH);
    fill(fillColor); //noStroke();

    triangle(0, 1, -.5, -1, .5, -1); // box(5, 5, 1);
    popMatrix();
    stroke(255);
  }

  void drawPath(){
    float[] from, to;

    for(int i=0; i<histCount-1; i++){
      from = posHist[i];
      to = posHist[i+1];
      stroke(pathColor, 255*i/histCount);

      line(from[X], from[Y], from[Z], to[X], to[Y], to[Z]);
    }

    line( posHist[histCount-1][X], posHist[histCount-1][Y], posHist[histCount-1][Z],
    pos.x, pos.y, pos.z );
  }

  // A variation on drawPath using glBegin() and glVertex()

  void drawPathGL(){

    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();

    gl.glBegin(GL.GL_LINE_STRIP);

    float r, g, b, a;

    float wavenumberFactor = TWO_PI * HARMONIC / pos.z;
    
    for(int i=1; i<histCount-1; i++){
      r = pathColorR+properTimeHist[i]/400;
      g = 0.5 + 0.5*cos((wavenumberFactor * properTimeHist[i])%TWO_PI);
      b = pathColorB;
      
      float passFactor = (properTimeHist[i]-properTimeHist[i-1])/(posHist[i][2] - posHist[i-1][2]);
      passFactor = (passFactor > 1) ? 1 : passFactor;
      
      a = g * passFactor * pathColorA * i / ((float)histCount) * (0.5 + 0.5*sin(TWO_PI *0.01 * properTimeHist[i]%100));

      gl.glColor4f(r, g, b, a); 
      gl.glVertex3fv(posHist[i], 0);
    }
    gl.glColor4f(pathColorR+properTimeHist[histCount-1]/400, pathColorG, pathColorB, pathColorA);
    gl.glVertex3f(pos.x, pos.y, pos.z);    
    gl.glEnd();

    pgl.endGL();
  }
  //
  void setPathColor(color c) {
    colorMode(RGB,1.0f);
    pathColor = c;
    pathColorR = red(c);
    pathColorG = green(c);
    pathColorB = blue(c);
    pathColorA = alpha(c);
  }

  int histCount;
  int histCountMax = 1000;

  float[][] posHist = new float[histCountMax][3];
  float[][] velHist = new float[histCountMax][3];
  float[] properTimeHist = new float[histCountMax];

  PVector pos;
  PVector vel;

  color fillColor;

  float pathColorR, pathColorG, pathColorB, pathColorA;
  color pathColor;

  float properTime=0;
}

/* A variation on drawPath() which pulses
 
 void drawPath(){
 float[] from, to;
 
 int alpha = abs((3*frameCount + (this.hashCode() >> 19)) % 510 - 255);
 
 for(int i=0; i<histCount-1; i++){
 from = posHist[i];
 to = posHist[i+1];
 stroke(pathColor, 255*i/histCount - alpha);
 
 line(from[0], from[1], from[2], to[0], to[1], to[2]);
 }
 
 line( posHist[histCount-1][0], posHist[histCount-1][1], posHist[histCount-1][2],
 pos.x, pos.y, pos.z );
 }
 */


/* A variation on drawPath using beginShape() and vertex()
 
 void drawPath(){
 
 beginShape();
 for(int i=0; i<histCount-1; i++){
 //stroke(pathColor, 255*i/histCount - alpha);
 vertex(posHist[i+1][0], posHist[i+1][1], posHist[i+1][2]);
 }
 vertex(pos.x,pos.y,pos.z);
 endShape();
 }
 */

