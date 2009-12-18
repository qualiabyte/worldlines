// Worldlines
// tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;
import javax.vecmath.*;
import geometry.*;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Particle[] particles;
Particle targetParticle;
ArrayList targets;

DefaultFrame restFrame;

ParticleUpdater particleUpdater;

ParticlesLayer particlesLayer;
InputDispatch inputDispatch;

Axes targetAxes;
ParticleGrid particleGrid;

float C = 1.0;
float timeDelta = 0.2;

// GUI Control Vars
public int MAX_PARTICLES = 500;
public int PARTICLES = MAX_PARTICLES/10; ///3;
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

public float PARTICLE_SIZE = 1.3;//0.75;
public float PARTICLE_SIZE_MAX = 10;
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

// Data Files
String PARTICLE_IMAGE = "particle.png";//_reticle.png";
String bundledFont = "VeraMono.ttf";

float fpsRecent, prevFrameCount;
float seconds, prevSeconds, deltaSeconds;
float fpsMovingAvg;

ControlP5 controlP5;

Infobox myInfobox;

void setup() {
  size(900, 540, OPENGL);//900, 540, 1280, 900, OPENGL);
  
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
  controlP5.addSlider("PARTICLE_SIZE", 0f, PARTICLE_SIZE_MAX, PARTICLE_SIZE, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
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
  //targetParticle = new Particle(new Vector3f(0,0,0), new Vector3f(1E-7, 0, 0));
  targetParticle = new Particle();
  targetParticle.setVelocity(1E-7, 0);
  targetParticle.setPosition(0, 0, 0);
  targetParticle.setFillColor(color(#F01B5E));
  
  particles = new Particle[MAX_PARTICLES];
  particles[0] = targetParticle;  

  for(int i=1; i<MAX_PARTICLES; i++){

    float x = pow(10, START_POS_DISPERSION_X);
    float y = pow(10, START_POS_DISPERSION_Y);
    
    Vector3f pos = new Vector3f(random(-x, +x), random(-y, +y), 0);
    
    // Exponentially weight distribution of velocities towards lightspeed
    float vel_mag = 1-pow(random(1, 2), -START_VEL_DISPERSION);
    float heading = random(TWO_PI);
    
    float vx = vel_mag*cos(heading);
    float vy = vel_mag*sin(heading)*(pow(1.5, -START_VEL_ECCENTRICITY));
    
    Vector3f vel = new Vector3f(vx, vy, 0);
    
    particles[i] = new Particle(pos, vel);
    particles[i].setFillColor(color(#1B83F0));
  }
  
  println("target pos: " + targetParticle.position.x + ", " + targetParticle.position.y );
  println("target direction: " + targetParticle.velocity.direction);
  println("target magnitude: " + targetParticle.velocity.magnitude);
  println("target gamma:     " + targetParticle.velocity.gamma);
  
  targets = new ArrayList();
  for (int i=0; i<TARGETS; i++) {
    addTarget(particles[i]);
  }
  
  kamera = new Kamera();
  
  particlesLayer = new ParticlesLayer(particles, PARTICLE_IMAGE, kamera);
  inputDispatch = new InputDispatch(targets);
  
  particleGrid = new ParticleGrid(3*50, 5*1000);
  targetAxes = new Axes((Frame)targetParticle);
  
  Velocity restFrameVel = new Velocity(0, 0);
  
  restFrame = new DefaultFrame();
  restFrame.setVelocity(0,0);
  
  // THREADING
  particleUpdater = new ParticleUpdater(targetParticle, particles);
  //Relativity.loadFrame(targetParticle);
  //particleUpdater.start();

  frameRate(30);
  //hint(DISABLE_DEPTH_SORT);
}

void addTarget(Particle p){
  targets.add(p);
  p.fillColor = TARGET_COLOR;
}

float[] vel = new float[3];

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
  //directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, 0.5, -0.5);
  //directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, -0.5, -0.5);
  //strokeWeight(STROKE_WIDTH);
  
  // UPDATE SCENE
  inputDispatch.update();
  
  float dilationFactor = TOGGLE_TIMESTEP_SCALING ? targetParticle.velocity.gamma : 1.0;
  float dt = timeDelta * dilationFactor;
  
  particleUpdater.dt = dt;
  
  Relativity.loadFrame(targetParticle);
  
  boolean SIMPLE_UPDATES = true;
  
  if (SIMPLE_UPDATES){
    
    for (int i=0; i<PARTICLES; i++) {
      particles[i].update(dt);
      particles[i].updateTransformedHist();
    }
  }
  else {
    // UPDATE TARGET  
    targetParticle.update(dt);  
    targetParticle.updateTransformedHist();
    
    // UPDATE NON-TARGETS
    for (int i=0; i<PARTICLES; i++) {
      
      if ( particles[i] == targetParticle)
      {
        continue;
      }
      else if( particles[i].xyt_prime[2] > targetParticle.xyt_prime[2] )
      {
        particles[i].updateTransformedHist();
        continue;
      } 
      else {
        particles[i].update(dt);
        particles[i].updateTransformedHist();
      }
    }
  }
  
  // CAMERA PREP
  kamera.updateTarget(targetParticle.getDisplayPosition());
  kamera.update(timeDelta);
  
  // RENDER
  particlesLayer.draw();
  //particleGrid.draw(targetParticle.xyt);
  //targetAxes.drawAxes();
  
  // UPDATE FPS
  seconds = 0.001 * millis();
  deltaSeconds = seconds - prevSeconds;
  
  if (deltaSeconds > 1) {
    fpsRecent = (frameCount - prevFrameCount) / deltaSeconds;
    prevSeconds = seconds;
    prevFrameCount = frameCount;
  }
  
  float[] p1 = targetParticle.getDisplayPosition();
  
  // INFO LAYER
  myInfobox.print(
  + (int) seconds + " seconds\n"
  + (int) fpsRecent +  "fps (" + (int)(frameCount / seconds) + "avg)\n"
  + "targetParticle.pos.z:      " + nf(targetParticle.position.z, 3, 2) + " seconds\n"
  + "kamera.target.pos.x:      " + nf(kamera.target.x, 3, 2) + " seconds\n"
  + "targetParticle.properTime: " + nf(targetParticle.properTime, 3, 2) + " seconds\n"
  + "targetParticle.velMag:     " + nf(targetParticle.velocity.magnitude, 1, 8) + " c\n"
  + "Controls: W,A,S,D to move; Right mouse button toggles camera rotation"
  + "\n displayPos: " + p1[0] + " " + p1[1] + " " + p1[2]
  );
  
  // GUI LAYER
  imageMode(CORNERS);
  camera();
  noLights(); //lights();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E7);
  
  controlP5.draw();
}

class ParticlesLayer {
  Particle[] particles;
  PImage particleImage;
  Kamera kamera;
  
  ParticlesLayer (Particle[] particles, String particleImagePath, Kamera kamera) {
    this.particles = particles;
    this.kamera = kamera;
    this.particleImage = loadImage(particleImagePath);
  }
  
  void draw() {
    
    restFrame.setPosition(targetParticle.getPosition());
    restFrame.setVelocity(0, 0);
        
    // GL SECTION
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
    Frame[] displayFrames = new Frame[] {
      restFrame,
      targetParticle
    };
    
    targetParticle.drawHeadGL(gl);
    Vector3f[] intersections = new Vector3f[MAX_PARTICLES*displayFrames.length];
    int intersectionCount = 0;
    
    Vector3f intersection = new Vector3f();
    
    for (int i=0; i < PARTICLES; i++) {
      
      particles[i].drawPathGL(gl);
      targetAxes.drawGL(gl, (Frame)particles[i]);
      
      for (int j=0; j < displayFrames.length; j++) {
        
        intersection = particles[i].getIntersection(displayFrames[j]);
        
        particles[i].drawHeadGL(gl, intersection);
        intersections[intersectionCount++] = intersection;
        
        //particles[i].drawIntersectionGL(gl, displayFrames[j]);
        //particles[i].drawIntersectionGL(gl, (Frame)targetParticle);
        //particles[i].drawIntersectionGL(gl, (Frame)restFrame);
      }
    }
    gl.glBlendFunc(GL.GL_SRC_ALPHA , GL.GL_ALPHA);
    pgl.endGL();
    
    // PROCESSING SECTION
    pushMatrix();
    imageMode(CENTER);
    
    //for (int i=0; i<PARTICLES; i++) {
    for (int i=0; i<intersectionCount; i++) {
      
      //float[] xyt_prime = new float[3];
      //intersections[i].get(xyt_prime);
      
      //float[] xyt_prime = particles[i].getDisplayPosition();
      
      float x = intersections[i].x;
      float y = intersections[i].y;
      float z = intersections[i].z;
      
      //noStroke();
      
      // BILLBOARDING
      pushMatrix();
      
      float dx = kamera.pos.x - x;
      float dy = kamera.pos.y - y;
      float dz = kamera.pos.z - z;
      float dxy = sqrt(dx*dx + dy*dy);
      float dxyz = sqrt(dz*dz + dxy*dxy);
      
      float theta_ct = atan2(dy, dx);
      float phi_ct = atan2(dz, dxy);
  
      translate(x, y, z);
      rotateZ(theta_ct);
      rotateY(-HALF_PI-phi_ct);
      rotateZ(-HALF_PI);
  
      float pulseFactor = 1 - 0.5*sin(particles[i].properTime);
      float dim = LIGHTING_PARTICLES * constrain(dxyz * 0.005, 0, 1);
      scale(PARTICLE_SIZE * 0.1*pulseFactor*0.0015*dxyz);
      
      tint(lerpColor(#FFFFFF, particles[i].fillColor, 0.5*pulseFactor), pulseFactor);
      image(particleImage, 0, 0);
      
      popMatrix();
    }
    noTint();
    popMatrix();
  }
}

class InputDispatch {
  ArrayList targets;
  
  float buttonPressure;
  float buttonAccumulateFactor = 0.02;
  float buttonDecayFactor = 0.95;
  
  InputDispatch(ArrayList targets) {
     this.targets = targets;
  }
  
  void update() {
    
    if (INPUT_UP || INPUT_DOWN || INPUT_LEFT || INPUT_RIGHT) {
      
      float x = 0;
      float y = 0;
      
      if      (INPUT_UP)   { y += -1.0; }
      else if (INPUT_DOWN) { y += +1.0; }
      else if (INPUT_LEFT) { x += -1.0; }
      else if (INPUT_RIGHT){ x += 1.0; }
  
      float direction = atan2(y, x);
      float offset = kamera.azimuth - HALF_PI;
      
      buttonPressure += (1 - buttonPressure) * buttonAccumulateFactor;
      constrain(buttonPressure, 0, 1.0);      
      
      //println("Nudge: Direction: " + direction / PI);
      //println("Nudge: Offset:    " + offset / PI);
      
      for (int i=0; i < targets.size(); i++) {
        nudge((Particle)targets.get(i), direction + offset, buttonPressure);
      }
    }
    else {
      buttonPressure *= buttonDecayFactor;
    }
  }
  
  void nudge(Particle particle, float theta, float amt) {
      
      float momentumScale = 0.05;
      float momentumNudge = 0.0001 ;
      
      float v_mag = particle.velocity.magnitude;
      
      float p = particle.mass * particle.velocity.gamma * v_mag;
      
      float vx = targetParticle.velocity.vx;
      float vy = targetParticle.velocity.vy;
      
      float heading_initial = particle.velocity.direction;
      
      float angleDiff = heading_initial - theta;
      
      // Help user slow down at high speeds, quickly but smoothly
      if ((v_mag > 0.99999) && abs(abs(angleDiff)-PI) < TWO_PI/5.0) {
        theta = heading_initial + PI + angleDiff * (1.0 - v_mag);
        momentumScale = 0.5;
      }
  
      float dp = amt * (momentumScale * p + momentumNudge);
  
      float dp_x = dp * cos(theta);
      float dp_y = dp * sin(theta);
      
      //println("Nudging: dp: " + dp + "theta: " + theta / PI);
  
      particle.addImpulse(dp_x, dp_y);
  }
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
    targetParticle.setFillColor(color(#F01B5E));
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

