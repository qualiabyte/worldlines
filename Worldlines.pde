//Worldlines
//tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Particle[] particles;
Particle targetParticle;

//PVector target;
//PVector prevTarget;

float C = 1.0;
float timeDelta = 0.2;

// GUI Control Vars
public int MAX_PARTICLES = 1000;
public int PARTICLES = MAX_PARTICLES/3;

public float MAX_START_POS_DISPERSION = 6;
public float START_POS_DISPERSION_X = 0;
public float START_POS_DISPERSION_Y = 0;

public float MAX_START_VEL_DISPERSION = 20;
public float START_VEL_DISPERSION = 5.4; //4.2; //1.8;

public float MAX_START_VEL_ECCENTRICITY = 15;
public float START_VEL_ECCENTRICITY = 1.95;

public float HARMONIC_FRINGES = 3.4;
public float HARMONIC_FRINGES_MAX = 16;

public float HARMONIC_CONTRIBUTION = -0.5;
public float HARMONIC_CONTRIBUTION_MIN = -1;
public float HARMONIC_CONTRIBUTION_MAX = 0;

public boolean TOGGLE_TIMESTEP_SCALING = true;
public boolean TOGGLE_SPATIAL_TRANSFORM = true;

public float LIGHTING = 0.75;
public float STROKE_WIDTH = 1.1;
public float STROKE_WIDTH_MAX = 8.0;

public float MAX_INPUT_RESPONSIVENESS = 1.0;
public float INPUT_RESPONSIVENESS = 0.8;

// Input Device Vars
public boolean MOUSELOOK = true;
public boolean INPUT_RIGHT;
public boolean INPUT_LEFT;
public boolean INPUT_UP;
public boolean INPUT_DOWN;

String bundledFont = "VeraMono.ttf";

float fpsRecent, prevFrameCount;
float seconds, prevSeconds, deltaSeconds;
float fpsMovingAvg;

ControlP5 controlP5;

Infobox myInfobox;

void setup() {
  size(900, 540, OPENGL);
  
  myInfobox = new Infobox(loadBytes(bundledFont), (int)(0.025 * height));
  
  String tabLabel;
  int numGlobalControls = 0;
  int numTabControls = 0;
  
  int bWidth = 20;
  int bHeight = 20;
  int bSpacingY = bHeight + 15;
  int sliderWidth = bWidth*5;
  
  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
  controlP5.setColorForeground(#093967); //173A7E);
  
  // Global Controls (All Tabs)
  controlP5.addButton("setup", 0, 10, ++numGlobalControls*bSpacingY, 2*bWidth, bHeight).setLabel("RESTART");
  controlP5.addSlider("PARTICLES", 0, MAX_PARTICLES, PARTICLES, 10, ++numGlobalControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addToggle("TOGGLE_TIMESTEP_SCALING",TOGGLE_TIMESTEP_SCALING,10,++numGlobalControls*bSpacingY,bWidth,bHeight);
  controlP5.addToggle("TOGGLE_SPATIAL_TRANSFORM", TOGGLE_SPATIAL_TRANSFORM, 10, ++numGlobalControls*bSpacingY,bWidth,bHeight);
  
  String[] globalLabels = new String[] {"setup", "PARTICLES", "TOGGLE_TIMESTEP_SCALING", "TOGGLE_SPATIAL_TRANSFORM"};
  
  for (int i=0; i<globalLabels.length; i++) {
    controlP5.controller(globalLabels[i]).moveTo("global");
  }
  
  // Main Tab
  tabLabel = "Main";
  controlP5.tab("default").setLabel(tabLabel);
  numTabControls = numGlobalControls;
  controlP5.addSlider("HARMONIC_FRINGES", 0, HARMONIC_FRINGES_MAX, HARMONIC_FRINGES, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("HARMONIC_CONTRIBUTION", HARMONIC_CONTRIBUTION_MIN, HARMONIC_CONTRIBUTION_MAX, HARMONIC_CONTRIBUTION, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("INPUT_RESPONSIVENESS", 0f, MAX_INPUT_RESPONSIVENESS, INPUT_RESPONSIVENESS, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("LIGHTING", 0f, 1.0f, LIGHTING, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("STROKE_WIDTH", 0f, STROKE_WIDTH_MAX, STROKE_WIDTH, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  
  // Setup Tab
  tabLabel = "SETUP";
  controlP5.addTab(tabLabel);
  numTabControls = numGlobalControls;
  controlP5.addSlider("START_POS_DISPERSION_X", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION_X, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);;
  controlP5.addSlider("START_POS_DISPERSION_Y", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION_Y, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);;
  controlP5.addSlider("START_VEL_DISPERSION", 0, MAX_START_VEL_DISPERSION, START_VEL_DISPERSION, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);;
  controlP5.addSlider("START_VEL_ECCENTRICITY", 0, MAX_START_VEL_ECCENTRICITY, START_VEL_ECCENTRICITY, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);;

  particles = new Particle[MAX_PARTICLES];

  for(int i=0; i<MAX_PARTICLES; i++){

    float x = pow(10, START_POS_DISPERSION_X);
    float y = pow(10, START_POS_DISPERSION_Y);
    
    PVector pos = new PVector(random(-x, +x), random(-y, +y));
    
    // Exponentially weight distribution of velocities towards lightspeed
    float vel_mag = 1-pow(random(1, 2), -START_VEL_DISPERSION);
    float heading = random(TWO_PI);
    
    float vx = vel_mag*cos(heading);
    float vy = vel_mag*sin(heading)*(pow(1.5, -START_VEL_ECCENTRICITY));

    PVector vel = new PVector(vx, vy);
    
    particles[i] = new Particle(pos, vel);
    particles[i].fillColor = color(#1B83F0);
  }

  particles[0] = new Particle(new PVector(0,0,0), new PVector(0,0,0));
  targetParticle = particles[0];
  targetParticle.fillColor = color(#F01B5E);

    
  kamera = new Kamera();
  kamera.target = targetParticle.pos;

  frameRate(90);
  //hint(DISABLE_DEPTH_SORT);
}

void draw() {
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glScalef(1,1,1);
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  //gl.glClear(GL.GL_DEPTH_BUFFER_BIT);
  pgl.endGL();
  background(30); //noLights();
  
  directionalLight(LIGHTING, LIGHTING, LIGHTING, 0.5, 0.5, -1);
  directionalLight(LIGHTING, LIGHTING, LIGHTING, 0.5, -0.5, -1);
    
  strokeWeight(STROKE_WIDTH);

  processUserInput(targetParticle);

  float dilationFactor = TOGGLE_TIMESTEP_SCALING ? 
                         targetParticle.gamma : 1.0;
                         
  for (int i=0; i<PARTICLES; i++) {
    particles[i].update(timeDelta * dilationFactor);
  }
  
  kamera.update(timeDelta);
  
  for (int i=0; i<PARTICLES; i++) {
    particles[i].draw();
  }
  
  seconds = 0.001 * millis();
  deltaSeconds = seconds - prevSeconds;
  
  if (deltaSeconds > 1) {
    fpsRecent = (frameCount - prevFrameCount) / deltaSeconds;
    prevSeconds = seconds; 
    prevFrameCount = frameCount;
  }
  
  myInfobox.print(
  + (int) seconds + " seconds\n"
  + (int) fpsRecent +  "fps (" + (int)(frameCount / seconds) + "avg)\n"
  + "targetParticle.pos.z:      " + nf(targetParticle.pos.z, 3, 2) + "c\n"
  + "targetParticle.properTime: " + nf(targetParticle.properTime, 3, 2) + "c\n"
  + "targetParticle.velMag:     " + nf(targetParticle.velMag, 1, 8) + "c\n"
  + "\nControls: W,A,S,D to move; Right mouse button toggles camera rotation"
  );

  // ControlP5 needs some scene defaults to render GUI layer correctly
  camera();
  noLights(); //lights();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E7);
  
  controlP5.draw();
}

void processUserInput(Particle particle) {
  
  if (INPUT_UP || INPUT_DOWN || INPUT_LEFT || INPUT_RIGHT) {
    
    float x = 0;
    float y = 0;
    
    if      (INPUT_UP)   { y += -1.0; }
    else if (INPUT_DOWN) { y += +1.0; }
    else if (INPUT_LEFT) { x += -1.0; }
    else if (INPUT_RIGHT){ x += 1.0; }

    float direction = atan2(y, x);
    float offset = kamera.azimuth - PI/2.0;
    
    //println("Nudge: Direction: " + direction / PI);
    //println("Nudge: Offset:    " + offset / PI);
    
    nudge(particle, direction + offset);
  }
}

void nudge(Particle particle, float theta) {
    
    float momentumScale = 0.05;
    float momentumNudge = 0.001;
    
    float v_mag = particle.velMag;
    
    float p = particle.mass * particle.gamma * v_mag;
    
    float vx = targetParticle.vel.x;
    float vy = targetParticle.vel.y;
    
    float heading_initial = atan2(vy, vx);
    
    float angleDiff = heading_initial - theta;
    
    if ((v_mag > 0.99999) && abs(abs(angleDiff)-PI) < TWO_PI/5.0) {
      theta = heading_initial + PI + angleDiff * (1.0 - v_mag);
      momentumScale = 0.5;
    }

    float dp = momentumScale * p + momentumNudge;

    float dp_x = dp * cos(theta);
    float dp_y = dp * sin(theta);
    
    //println("Nudging: dp: " + dp + "theta: " + theta / PI);

    targetParticle.addImpulse(dp_x, dp_y);
}

void mousePressed() {
  if (mouseButton == RIGHT) {
    MOUSELOOK = !MOUSELOOK;
    cursor(MOUSELOOK ? MOVE : ARROW);
  }
}

void keyPressed() {

  switch (key) {
    case 'w' : INPUT_UP = true; break;
    case 'W' : INPUT_UP = true; break;
    case 'a' : INPUT_LEFT = true; break;
    case 'A' : INPUT_LEFT = true; break;
    case 's' : INPUT_DOWN = true; break;
    case 'S' : INPUT_DOWN = true; break;
    case 'd' : INPUT_RIGHT = true; break;
    case 'D' : INPUT_RIGHT = true; break;
   }
}

void keyReleased() {

  switch (key) {
    case 'w' : INPUT_UP = false; break;
    case 'W' : INPUT_UP = false; break;
    case 'a' : INPUT_LEFT = false; break;
    case 'A' : INPUT_LEFT = false; break;
    case 's' : INPUT_DOWN = false; break;
    case 'S' : INPUT_DOWN = false; break;
    case 'd' : INPUT_RIGHT = false; break;
    case 'D' : INPUT_RIGHT = false; break;
  }
}

class Kamera {
  
  Kamera() {
    radius = 100;
    azimuth = PI;
    zenith = PI/6.0;
    target = new PVector(0,0,0);
    
    pos = new PVector();
    updatePosition();
    
    float fov = PI/3.0;
    perspective(fov, width/height, 1, 15000000);
    
    addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
      public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
      }
    });
  }
  
  void mouseWheel(int delta) {
    mouseWheel -= delta;
    println(mouseWheel);
    
    radiusVel += mouseWheel;
  }
  
  void updatePosition() {
    pos.x = target.x + radius * sin(zenith) * cos(azimuth);
    pos.y = target.y + radius * sin(zenith) * sin(azimuth);
    pos.z = target.z + radius * cos(zenith);
  }
  
  void update(float dt) {
    
    if (MOUSELOOK) {
      zenithVel -= ((float)(mouseY - pmouseY))/10.0;
      azimuthVel += ((float)(mouseX - pmouseX))/10.0;
    }
    
    radiusVel += mouseWheel;
    mouseWheel *= 0.1;
    
    radius = abs((float)(radius - radius * radiusVel / 60.0));
    radiusVel *= velDecay;
    
    azimuth = (azimuth + azimuthVel / 60.0) % (TWO_PI);
    azimuthVel *= velDecay;
    
    zenith = constrain(zenith + zenithVel / 60.0, 0.0001, PI - 0.0001);
    zenithVel *= velDecay;
    
    updatePosition();
    
    upX = 0;
    upY = 0;
    upZ = -1;
    
    // Keep rotation smooth at zenith extremes, when pos gets near limit for floats
    // Done piecewise to work around oddities of the camera up vector in processing
    if (zenith < PI / 10.0) {
      upX = cos(azimuth);
      upY = sin(azimuth);
      upZ = 0;
    }
    else if((PI - zenith) < PI / 10.0) {
      upX = -cos(azimuth);
      upY = -sin(azimuth);
      upZ = 0;
    }
    
    camera(pos.x,     pos.y,     pos.z,
           target.x,  target.y,  target.z,
           upX,       upY,      upZ);
  }
  
  float mouseWheel;
  
  float velDecay = 0.9;
  
  float radiusVel;
  float azimuthVel;
  float zenithVel;
  
  float radius;
  float azimuth;
  float zenith;
  
  float upX, upY, upZ;
  
  PVector pos;
  PVector target;
}
