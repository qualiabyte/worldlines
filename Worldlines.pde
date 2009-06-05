// Worldlines
// tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Particle[] particles;
Particle targetParticle;
ArrayList targets;

float C = 1.0;
float timeDelta = 0.2;

// GUI Control Vars
public int MAX_PARTICLES = 1000;
public int PARTICLES = MAX_PARTICLES/3;
public int TARGETS = 1;
public int TARGET_COLOR = #F01B5E;
public int PARTICLE_COLOR = #1B83F0;

public float MAX_START_POS_DISPERSION = 3;
public float START_POS_DISPERSION_X = 0;
public float START_POS_DISPERSION_Y = 0;

public float MAX_START_VEL_DISPERSION = 20;
public float START_VEL_DISPERSION = 5.4; //4.2; //1.8;

public float MAX_START_VEL_ECCENTRICITY = 15;
public float START_VEL_ECCENTRICITY = 1.95;

public void randomize() {
  START_POS_DISPERSION_X = random(MAX_START_POS_DISPERSION);
  START_POS_DISPERSION_Y = random(MAX_START_POS_DISPERSION);
  START_VEL_DISPERSION = random(MAX_START_VEL_DISPERSION);
  START_VEL_ECCENTRICITY = random(MAX_START_VEL_ECCENTRICITY);
  TARGETS = (int)random(PARTICLES) / 3;
  setup();
}

public float HARMONIC_FRINGES = 3.4;
public float HARMONIC_FRINGES_MAX = 16;

public float HARMONIC_CONTRIBUTION = 0.5;
public float HARMONIC_CONTRIBUTION_MIN = 0;
public float HARMONIC_CONTRIBUTION_MAX = 1;

public boolean TOGGLE_TIMESTEP_SCALING = true;
public boolean TOGGLE_SPATIAL_TRANSFORM = true;
public boolean TOGGLE_TEMPORAL_TRANSFORM = true;

public void toggleSpatialTransform () {
  TOGGLE_SPATIAL_TRANSFORM = Relativity.TOGGLE_SPATIAL_TRANSFORM ^= true;
}
public void toggleTemporalTransform () {
  TOGGLE_TEMPORAL_TRANSFORM = Relativity.TOGGLE_TEMPORAL_TRANSFORM ^= true;
}

public float LIGHTING_PARTICLES = 0.75;
public float LIGHTING_WORLDLINES = 0.8;
public float STROKE_WIDTH = 2.0;
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
  size(900, 600, OPENGL);
  
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
  controlP5.setColorForeground(#093967);
  
  // Global Controls (All Tabs)
  controlP5.addButton("setup", 0, 10, ++numGlobalControls*bSpacingY, 2*bWidth, bHeight).moveTo("global");
  controlP5.controller("setup").setLabel("RESTART");
  controlP5.addButton("randomize", 0, (int)3*bWidth, numGlobalControls*bSpacingY, (int)(2.6*bWidth), bHeight).moveTo("global");
  controlP5.addSlider("PARTICLES", 0, MAX_PARTICLES, PARTICLES, 10, ++numGlobalControls*bSpacingY, sliderWidth, bHeight).moveTo("global");
  
  // Main Tab
  tabLabel = "Main";
  controlP5.tab("default").setLabel(tabLabel);
  numTabControls = numGlobalControls;
  controlP5.addSlider("HARMONIC_FRINGES", 0, HARMONIC_FRINGES_MAX, HARMONIC_FRINGES, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("HARMONIC_CONTRIBUTION", HARMONIC_CONTRIBUTION_MIN, HARMONIC_CONTRIBUTION_MAX, HARMONIC_CONTRIBUTION, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("INPUT_RESPONSIVENESS", 0f, MAX_INPUT_RESPONSIVENESS, INPUT_RESPONSIVENESS, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("LIGHTING_PARTICLES", 0f, 1.0f, LIGHTING_PARTICLES, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("LIGHTING_WORLDLINES", 0f, 1.0f, LIGHTING_WORLDLINES, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("STROKE_WIDTH", 0f, STROKE_WIDTH_MAX, STROKE_WIDTH, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addToggle("TOGGLE_TIMESTEP_SCALING",TOGGLE_TIMESTEP_SCALING,10,++numTabControls*bSpacingY,bWidth,bHeight);
  controlP5.addToggle("toggleSpatialTransform", TOGGLE_SPATIAL_TRANSFORM, 10, ++numTabControls*bSpacingY,bWidth,bHeight);
  controlP5.addToggle("toggleTemporalTransform", TOGGLE_TEMPORAL_TRANSFORM, 10, ++numTabControls*bSpacingY,bWidth,bHeight);
  
  Relativity.TOGGLE_SPATIAL_TRANSFORM = TOGGLE_SPATIAL_TRANSFORM;
  Relativity.TOGGLE_TEMPORAL_TRANSFORM = TOGGLE_TEMPORAL_TRANSFORM;

  // Setup Tab
  tabLabel = "SETUP";
  controlP5.addTab(tabLabel);
  numTabControls = numGlobalControls;
  controlP5.addSlider("START_POS_DISPERSION_X", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION_X, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);;
  controlP5.addSlider("START_POS_DISPERSION_Y", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION_Y, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);;
  controlP5.addSlider("START_VEL_DISPERSION", 0, MAX_START_VEL_DISPERSION, START_VEL_DISPERSION, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);;
  controlP5.addSlider("START_VEL_ECCENTRICITY", 0, MAX_START_VEL_ECCENTRICITY, START_VEL_ECCENTRICITY, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);;

  // SCENE OBJECTS
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

  //particles[0] = new Particle(new PVector(0,0,0), new PVector(0,0,0));
  targetParticle = particles[0];
  targetParticle.fillColor = color(#F01B5E);
  
  targets = new ArrayList();
  for (int i=0; i<TARGETS; i++) {
    addTarget(particles[i]);
  }
  
  kamera = new Kamera();
  kamera.target = targetParticle.pos.get();

  frameRate(30);
  //hint(DISABLE_DEPTH_SORT);
}

void addTarget(Particle p){
  targets.add(p);
  p.fillColor = TARGET_COLOR;
}

float[] xyt = new float[3];
float[] vel = new float[3];
float[] xyt_prime = new float[3];

void draw() {
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glScalef(1,1,1);
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  gl.glLineWidth(STROKE_WIDTH);
  pgl.endGL();
  
  // SCENE PREP
  background(30);
  directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, 0.5, -1);
  directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, -0.5, -1);
  //strokeWeight(STROKE_WIDTH);

  // UPDATE SCENE
  processUserInput(targets);

  float dilationFactor = TOGGLE_TIMESTEP_SCALING ? targetParticle.gamma : 1.0;
  float dt = timeDelta * dilationFactor;
  
  for (int i=0; i<PARTICLES; i++) {
    particles[i].update(dt);
  }

  // CAMERA PREP
  targetParticle.pos.get(xyt);
  Relativity.loadObserver(xyt);
  Relativity.loadVel(targetParticle.vel.x, targetParticle.vel.y);
  Relativity.applyTransforms(xyt, xyt_prime);
  
  kamera.updateTarget(xyt_prime);
  kamera.update(timeDelta);
  
  // RENDER
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  for (int i=0; i<PARTICLES; i++) {
    particles[i].draw();
  }
  pgl.endGL();
  
  for (int i=0; i<PARTICLES; i++) {
    particles[i].pos.get(xyt);
    Relativity.applyTransforms(xyt, xyt_prime);
    particles[i].drawHead(xyt_prime[0], xyt_prime[1], xyt_prime[2]);
  }
  
  // UPDATE FPS
  seconds = 0.001 * millis();
  deltaSeconds = seconds - prevSeconds;
  
  if (deltaSeconds > 1) {
    fpsRecent = (frameCount - prevFrameCount) / deltaSeconds;
    prevSeconds = seconds; 
    prevFrameCount = frameCount;
  }
  
  // INFO LAYER
  myInfobox.print(
  + (int) seconds + " seconds\n"
  + (int) fpsRecent +  "fps (" + (int)(frameCount / seconds) + "avg)\n"
  + "targetParticle.pos.t:      " + nf(targetParticle.pos.z, 3, 2) + " seconds\n"
  + "targetParticle.properTime: " + nf(targetParticle.properTime, 3, 2) + " seconds\n"
  + "targetParticle.velMag:     " + nf(targetParticle.velMag, 1, 8) + " c\n"
  + "\nControls: W,A,S,D to move; Right mouse button toggles camera rotation"
  );

  // GUI LAYER
  camera();
  noLights(); //lights();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E7);
  
  controlP5.draw();
}

void processUserInput(ArrayList targets) {
  
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
    
    for(int i=0; i < targets.size(); i++) {
      nudge((Particle)targets.get(i), direction + offset);
    }
  }
}

void nudge(Particle particle, float theta) {
    
    float momentumScale = 0.05;
    float momentumNudge = 0.0001;
    
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

    particle.addImpulse(dp_x, dp_y);
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
     
  if (key == ' ') {
    int i = (int)random(PARTICLES);
    targetParticle = particles[i];
    targetParticle.fillColor = color(#F01B5E);
    targets.add(particles[i]);
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
    updateUp();
    commit();
  }
  
  void updateTarget(float[] xyz) {
    
    updateTarget(xyz[0], xyz[1], xyz[2]);    
  }
  
  void updateTarget(float x, float y, float z) {
    target.x = x;
    target.y = y;
    target.z = z;
    
    updatePosition();
    updateUp();
    commit();
  }
   
  void updatePosition() {
    pos.x = target.x + radius * sin(zenith) * cos(azimuth);
    pos.y = target.y + radius * sin(zenith) * sin(azimuth);
    pos.z = target.z + radius * cos(zenith);
  }
  
  void updateUp() {
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
  }
  
  void commit() {
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
