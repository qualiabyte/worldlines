// Worldlines
// tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;

import javax.vecmath.*;
import java.util.List;
import java.awt.geom.Rectangle2D;

import com.sun.opengl.util.texture.*;
import com.sun.opengl.util.BufferUtil;
import java.nio.ByteBuffer;
import java.nio.Buffer;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Matrix3f lorentzMatrix;
Matrix3f inverseLorentzMatrix;

List scenes;
List particles;

Scene myTwinParticleScene;

Particle targetParticle;
ArrayList targets;
ArrayList emissions;

RigidBody targetRigidBody;
ArrayList rigidBodies;

Selector particleSelector;
Selector labelSelector;

FanSelection myFanSelection;

DefaultFrame originFrame;
DefaultFrame restFrame;

ParticlesLayer particlesLayer;
InputDispatch inputDispatch;

Axes myAxes;

float C = 1.0;

FpsTimer myFpsTimer;

// GUI Control Vars
public int PARTICLES = 1;//50;

public int TARGET_COLOR = #F01B5E;
public int PARTICLE_COLOR = #1B83F0;

// Input Device Vars
public boolean MOUSELOOK = false;
public boolean INPUT_RIGHT;
public boolean INPUT_LEFT;
public boolean INPUT_UP;
public boolean INPUT_DOWN;

// Data Files
String PARTICLE_IMAGE = "particle.png";//_reticle.png";
String bundledFont = "VeraMono.ttf";

ControlP5 controlP5;

void setup() {
  size(900, 540, OPENGL);
  //size(1280, 900, OPENGL);
  //size(1100, 700, OPENGL);
  
  frameRate(45);
  //hint(DISABLE_DEPTH_SORT);
  
  restart(); //initScene();
}

VTextRenderer myVTextRenderer;
Infobox myInfobox;
Labelor myLabelor;

static ControlMap prefs;

void controlEvent(controlP5.ControlEvent event) {
  prefs.handleControlEvent(event);
}

// CONTROLP5 CALLBACK
public void playStatus() {
  StateControl c = (StateControl) prefs.getControl("playStatus");
  c.setState( (c.getState() == "paused") ? "playing" : "paused" );
  
  Dbg.say("playStatus(): state -> " + c.getState());
  Dbg.say("playStatus(): label -> " + c.getLabel());
}
// CONTROLP5 CALLBACK
public void randomize() {
  
  String[] floatLabels = new String[] {
    "START_POS_DISPERSION",
    //"START_POS_X_SCALE",
    "START_POS_Y_SCALE",
    "START_VEL_DISPERSION", 
    "START_VEL_ECCENTRICITY"
  };
  
  for (int i=0; i<floatLabels.length; i++) {
    String label = floatLabels[i];
    FloatControl control = prefs.getFloatControl(label);
    
    float randomValue = random(control.max);
    control.setValue(randomValue);
  }
  setup();
}

ControlPanel[] buildControlPanels() {
  
  Control restart = new ButtonControl("restart");
  Control randomize = new ButtonControl("randomize");
  StateControl pause = new StateControl("playStatus", "playing", "PAUSE");
  pause.addState("paused", "PLAY");
  ControlPanel panel;
  
  // SETUP PANEL
  ControlPanel setupPanel = new ControlPanel("setup");
  panel = setupPanel;
  panel.addControl(restart);
  panel.addControl(randomize);
  panel.putInteger("PARTICLES", PARTICLES, 0, PARTICLES*5);
  panel.putInteger("TARGETS", 1, 1, PARTICLES); //3
  panel.putFloat("START_POS_DISPERSION", 2.6, 0, 4);
  panel.putFloat("START_POS_X_SCALE", 2.6, 0, 3);
  panel.putFloat("START_POS_Y_SCALE", 2.6, 0, 3);
  panel.putFloat("START_VEL_DISPERSION", 5.4, 0, 20);
  panel.putFloat("START_VEL_ECCENTRICITY", 1.95, 0, 15);
  panel.putFloat("START_VEL_X_SCALE", 1);
  panel.putFloat("START_VEL_Y_SCALE", 1);
  
  // MAIN PANEL
  ControlPanel mainPanel = new ControlPanel("default");
  mainPanel.setLabel("MAIN");
  panel = mainPanel;
  panel.addControl(pause);
  panel.addControl(restart);
  panel.addControl(randomize);
  panel.putFloat("timestep", 8, 0, 20);
  panel.putBoolean("PROPERTIME_SCALING", true);
  panel.putBoolean("toggle_Spatial_Transform", true);
  panel.putBoolean("toggle_Temporal_Transform", true);
  panel.putBoolean("1-D_control", true);
  panel.putBoolean("use_Emissions", true);
  panel.putBoolean("energy_Conservation", false);
  panel.putBoolean("show_Rigid_Bodies", true);
  //panel.putBoolean("showAxesGrid", false);
  
  AxesSettings targetAxesSettings = new AxesSettings();
  AxesSettings originAxesSettings = new AxesSettings();
  
  panel.putBoolean("show_Target_Axes_Grid", true).addUpdater(
    new AxesSettingsVisibilityUpdater(targetAxesSettings));
  panel.putBoolean("show_Origin_Axes_Grid", false).addUpdater(
    new AxesSettingsVisibilityUpdater(originAxesSettings));
  panel.putBoolean("show_Particle_Clock_Ticks", true);
  panel.putBoolean("show_Particle_Clock_Tick_Labels", true);
  //panel.putBoolean("show_All_Axes_Grid", false);
  //panel.putBoolean("showAllAxesLabels", false);
  
  // DEBUG PANEL
  ControlPanel debugPanel = new ControlPanel("debug");
  panel = debugPanel;
  //panel.putBoolean("useGL", true);
  panel.putInteger("maxEmissions", 50, 0, 500);
  //panel.putFloat("fov", 60, 0, 180);
  panel.putFloat("backgroundColorHue", 0.65f);// 0.59);// 64//
  panel.putFloat("backgroundColorSaturation", 0.48f);// 0.70);// 53//
  panel.putFloat("backgroundColorBrightness", 0.23f);//0.17f);// 0.31);// 28//
  panel.putFloat("cauchyGamma", 1, 0, 4);
  panel.putFloat("momentumNudge", 0.003, 0, 1);
  panel.putFloat("INPUT_RESPONSIVENESS", 0.13);
  //panel.putBoolean("brehmeDiagramCorrection", false);
  //panel.putBoolean("useMatrixForPathTransform", true);
  //panel.putFloat("kam_units_scale", 1, 0, 8);
  
  // GRAPHICS PANEL
  ControlPanel graphicsPanel = new ControlPanel("graphics");
  panel = graphicsPanel;
  panel.putFloat("PARTICLE_SIZE", 1.3, 0, 10);
  panel.putFloat("LIGHTING_WORLDLINES", 0.8);
  panel.putFloat("STROKE_WIDTH", 2, 0, 8);
  //panel.putFloat("LIGHTING_PARTICLES", 0.75);
  panel.putFloat("HARMONIC_FRINGES", 3.4, 0, 16);
  panel.putFloat("HARMONIC_CONTRIBUTION", 0.5);
  
  ControlPanel[] controlPanels = new ControlPanel[] {
    setupPanel,
    mainPanel,
    debugPanel,
    graphicsPanel
  };
  
  return controlPanels;
}

ControlMap buildPrefs(ControlPanel[] controlPanels) {
  ControlMap oldPrefs = prefs;
  ControlMap newPrefs = new ControlMap(controlPanels);
  
  if (oldPrefs != null) {
    copyControlValues(oldPrefs, newPrefs);
  }
  return newPrefs;
}

ControlP5 buildControlP5(ControlMap thePrefs) {
  
  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
  controlP5.setColorForeground(#093967);

  thePrefs.buildControlP5(controlP5);
  
  return controlP5;
}

//void initScene() {
void restart() {
  
  // BUILD CONTROL PANELS
  ControlPanel[] controlPanels = buildControlPanels();
  
  // BUILD PREFERENCES
  prefs = buildPrefs(controlPanels);
  
  prefs.put("particleImagePath", "particle_hard.png");//"particle_cushioned_core.png");
  prefs.put("selectedParticleImagePath", "particle_reticle.png");
  prefs.put("startPosWeight", "cauchy");
  
  // CONTROLP5
  controlP5 = buildControlP5(prefs);
  
  // FONT
  byte[] fontBytes = loadBytes(bundledFont);
  int fontSize = (int)(0.025 * height);
  Font font = loadFont(fontBytes, fontSize);
  
  myInfobox = new Infobox(font, fontSize);
  myVTextRenderer = new VTextRenderer(font.deriveFont((float)40), (int)(1*fontSize));
  myLabelor = new Labelor();
  
  // SCENE OBJECTS
  targets = new ArrayList();
  particles = new ArrayList();
  emissions = new ArrayList();
  rigidBodies = new ArrayList();
  
  // SCENES
  scenes = new ArrayList();
  
  // SELECTABLES
  myFanSelection = null;
  labelSelector = new Selector();
  particleSelector = new Selector(particles);
  
  // INIT LORENTZ FOR PARTICLE CREATION
  Velocity targetVelocity = new Velocity(0f, 0f); //1E-7f,0f);
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetVelocity);
  inverseLorentzMatrix = Relativity.getInverseLorentzTransformMatrix(targetVelocity);
  
  // TARGET PARTICLES
  //targetParticle = new Particle(targetPos, targetVel);
  targetParticle = new Particle();
  targetParticle.setVelocity(targetVelocity.vx, targetVelocity.vy);
  targetParticle.setPosition(0, 0, 0);
  
  addTarget(targetParticle);
  
  //Dbg.say("target pos: " + targetParticle.position.x + ", " + targetParticle.position.y);
  //Dbg.say("target direction: " + targetParticle.velocity.direction);
  //Dbg.say("target magnitude: " + targetParticle.velocity.magnitude);
  //Dbg.say("target gamma:     " + targetParticle.velocity.gamma);
  
  int numTargets = prefs.getInteger("TARGETS");
  
  Vector3f[] targetPositions = genPolygonVertices(numTargets);
  scaleVectors(targetPositions, 3);
  
  for (int i=1; i < numTargets; i++) {
    Particle p = new Particle(targetPositions[i], targetParticle.velocity);
    particles.add(p);
    addTarget(p);
  }
  
  // RIGID BODIES
  Vector3f[] bodyVertices = new Vector3f[] {
    new Vector3f(1, 0.25, 0),
    new Vector3f(1, -0.25, 0),
    new Vector3f(-1, -1, 0),
    new Vector3f(-1, +1, 0),
  };
  
  scaleVectors(bodyVertices, 10);
  
  targetRigidBody = new RigidBody(targetParticle, bodyVertices);
  addRigidBody(targetRigidBody);
  
  for (int i=1; i < numTargets; i++) {
    RigidBody rb = new RigidBody((Particle) particles.get(i), bodyVertices);
    addRigidBody(rb);
  }
  
  for (int i=1; i<prefs.getInteger("PARTICLES"); i++) {
    
    float xScale = prefs.getFloat("START_POS_X_SCALE");
    float yScale = prefs.getFloat("START_POS_Y_SCALE");
    
    float x, y;
    
    float rScale = pow(10, prefs.getFloat("START_POS_DISPERSION"));
    
    if (prefs.getString("startPosWeight") == "cauchy") {
      
      float cauchyGamma = prefs.getFloat("cauchyGamma");
      float radius = rScale * cauchyWeightedRandom(cauchyGamma);
      float theta = random(0, TWO_PI);
      
      x = radius * cos(theta) * xScale;
      y = radius * sin(theta) * yScale;
    }
    else {
      x = random(-xScale, +xScale);
      y = random(-yScale, +yScale);
    }
    
    Vector3f pos = new Vector3f(x, y, 0);
    
    // Exponentially weight distribution of velocities towards lightspeed
    float vel_mag = 1-pow(random(1, 2), -prefs.getFloat("START_VEL_DISPERSION"));
    float heading = random(TWO_PI);
    
    float velXScale = prefs.getFloat("START_VEL_X_SCALE");
    float velYScale = prefs.getFloat("START_VEL_Y_SCALE");
    
    float vx = velXScale * vel_mag * cos(heading);
    float vy = velYScale * vel_mag * sin(heading) * (pow(1.5, -prefs.getFloat("START_VEL_ECCENTRICITY")));
    
    Vector3f vel = new Vector3f(vx, vy, 0);
    
    Particle p = new Particle(pos, vel);
    p.setFillColor(color(#1B83F0));
    particles.add(p);
  }
  
  kamera = new Kamera();
  //kamera.setFov(prefs.getFloat("fov"));
  
  // FRAMES
  AxesSettings targetAxesSettings = (AxesSettings)((AxesSettingsVisibilityUpdater)prefs.getControl("show_Target_Axes_Grid").getUpdater()).toUpdate;
  AxesSettings originAxesSettings = (AxesSettings)((AxesSettingsVisibilityUpdater)prefs.getControl("show_Origin_Axes_Grid").getUpdater()).toUpdate;
  (targetParticle.headFrame).axesSettings = targetAxesSettings;
  targetParticle.getAxesSettings().setAxesGridVisible(true);
  targetParticle.getAxesSettings().setAxesLabelsVisible(true);
  targetParticle.getAxesSettings().setAxesVisible(true);
  
  originFrame = new DefaultFrame();
  originFrame.axesSettings = originAxesSettings;
  originFrame.getAxesSettings().setAxesVisible(true);
  originFrame.getAxesSettings().setSimultaneityPlaneVisible(false);
  originFrame.getAxesSettings().setAxesGridVisible(true);
  
  restFrame = new DefaultFrame();
  restFrame.setVelocity(0,0);
  //restFrame.setAxesVisible(true);
  //restFrame.getAxesSettings().setSimultaneityPlaneVisible(false);
  
  particlesLayer = new ParticlesLayer(particles, prefs.getString("particleImagePath"), kamera, particleSelector.selection);
  
  inputDispatch = new InputDispatch(targets);
  
  myAxes = new Axes((Frame)targetParticle);
  myFpsTimer = new FpsTimer();
  
  Dbg.say("controlP5.controller(\"show_Target_Axes_Grid\"): " + controlP5.controller("show_Target_Axes_Grid"));
  Dbg.say("  listenerSize():" + controlP5.controller("show_Target_Axes_Grid").listenerSize());
  
  myTwinParticleScene = new TwinParticleScene();
  addScene(myTwinParticleScene);
  
  prefs.notifyAllUpdaters();
  // THREADING
  //particleUpdater = new ParticleUpdater(targetParticle, particles);
  //particleUpdater.start();
}

abstract class Scene {
  void update() {};
}
class TwinParticleScene extends Scene {
  
  TwinParticlePair twinParticlePair;
  
  TwinParticleScene() {
    
    float relativeSpeed = 0.9;
    float turnaroundTime = 100;
    this.twinParticlePair = new TwinParticlePair(relativeSpeed, turnaroundTime);
    
    //addTarget(twinParticlePair.twinA);
    addParticle(twinParticlePair.twinA);
    addParticle(twinParticlePair.twinB);
    
    println(twinParticlePair.twinA);
    println(twinParticlePair.twinB);
  }
  
  void update() {
    this.twinParticlePair.update();
    
    if (twinParticlePair.isTripComplete()) {
      prefs.getStateControl("playStatus").setState("paused");
    }
  }
}

class TwinParticlePair {
  Particle twinA, twinB;
  float relativeSpeed;
  float turnaroundTime;
  float initialAgeTwinB;
  float elapsedTime;
  
  boolean returnHasBegun;
  
  /** Returns a list containing a new pair of "twin" Particles
    * @param relativeSpeed
    *    The relative speed between the frames of twins A and B,
    *    as a fraction of C
    * @param turnaroundTime
    *    Elapsed time before twinB decelerates and begins to return,
    *    in seconds as measured by twinB
    */
  TwinParticlePair(float relativeSpeed, float turnaroundTime) {
    
    this.relativeSpeed = relativeSpeed;
    this.turnaroundTime = turnaroundTime;
    //Velocity theDepartVelocity = new Velocity(relativeSpeed, 0.0f);
    
    twinA = new Particle();
    twinB = new Particle();
    twinB.setVelocity(relativeSpeed, 0);
    
    println("twinA position: " + nfVec(twinA.position, 3) + 
      "\ntwinB.getDisplayPosition(): " + twinB.getDisplayPosition() +
      "\ntwinA velocity: " + twinA.velocity.vx + ", " + twinA.velocity.vy);
    
    initialAgeTwinB = twinB.properTime;
  }
  
  void update() {

    if (!returnHasBegun) {
      elapsedTime = twinB.properTime - initialAgeTwinB;
      
      if (elapsedTime > turnaroundTime) {
        twinB.setVelocity(-twinB.velocity.vx, -twinB.velocity.vy);
        returnHasBegun = true;
      }
    }
  }
  
  boolean isTripComplete() {
    return (elapsedTime >= 2 * turnaroundTime);
  }
}

float cauchyWeightedRandom(float gamma) {
  
  while (true) {
    float x = random(0, gamma*20);
    float probability = cauchyPDF(x, gamma);
    if (probability > random(0, 1)) {
      return x;
    }
  }
}

float cauchyPDF(float x, float gamma) {
  return 1.0f / (PI*(1 + pow(x / gamma, 2.0)));
}

void addScene(Scene s) {
  if (!scenes.contains(s)) {
    scenes.add(s);
  }
}

void addParticle(Particle p) {
  if (!particles.contains(p)) {
    particles.add(p);
  }
  addSelectable(p);
}

void addSelectable(Particle p) {  
  if (!particleSelector.selectables.contains(p)) {
    particleSelector.addToSelectables(p);
  }
}

void addTarget(Particle p){
  
  addParticle(p);
  if ( ! targets.contains(p) ) {
    targets.add(p);
  }
  p.velocity.set(targetParticle.velocity);
  p.setFillColor(TARGET_COLOR);
}

void addEmission(Particle e){
  if ( prefs.getBoolean("use_Emissions") ) {
    
    addParticle(e);
    emissions.add(e);
    particleSelector.addToSelectables(e);
    e.setFillColor(color(0, 1, 0));
    
    if (emissions.size() > prefs.getInteger("maxEmissions")) {
      Particle oldEmission = (Particle) emissions.remove(0);
      particles.remove(oldEmission);
      particleSelector.drop(oldEmission);
    }
  }
}

void addRigidBody(RigidBody rb){
  rigidBodies.add(rb);  
}

void draw() {
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glScalef(1,1,1);
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  gl.glLineWidth(prefs.getFloat("STROKE_WIDTH"));
  
  pgl.endGL();
  
  // SCENE PREP
  //color c = #000020; //#3473F7;
  colorMode(HSB, 1.0f); //c = color((frameCount * 0.5)%255, 100, 75, 255);
  color c = color(
    prefs.getFloat("backgroundColorHue"),
    prefs.getFloat("backgroundColorSaturation"),
    prefs.getFloat("backgroundColorBrightness")
  );
  background(c);
  colorMode(RGB, 1.0f);
  //float LIGHTING_PARTICLES = 0.9;
  //directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, 0.5, -0.5);
  //directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, -0.5, -0.5);
  prefs.getFloat("STROKE_WIDTH");
  
  // UPDATE SCENE
//  inputDispatch.update();
  myTwinParticleScene.update();
  
  // UPDATE TARGET
  float dt;  
  if (prefs.getState("playStatus") != "paused") {
    
    float secondsPerFrame = myFpsTimer.getSecondsPerFrame();
    float dilationFactor = prefs.getBoolean("PROPERTIME_SCALING") ? targetParticle.velocity.gamma : 1.0;
    
    dt = secondsPerFrame * dilationFactor * prefs.getFloat("timestep");
  }
  else {
    dt = 0;
  }
  //particleUpdater.dt = dt;
  
  // UPDATE TARGET
  targetParticle.update(dt);
  
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetParticle.velocity);
  inverseLorentzMatrix = Relativity.getInverseLorentzTransformMatrix(targetParticle.velocity);
  Relativity.TOGGLE_SPATIAL_TRANSFORM = prefs.getBoolean("toggle_Spatial_Transform");
  Relativity.TOGGLE_TEMPORAL_TRANSFORM = prefs.getBoolean("toggle_Temporal_Transform");
  
  targetParticle.updateTransformedHist(lorentzMatrix);
  
  for (int i=0; i<particles.size(); i++) {
    Particle p = (Particle) particles.get(i);

    if (p != targetParticle) {
      p.update(dt);
      p.updateTransformedHist(lorentzMatrix);
    }
  }
  
  // CAMERA PREP
  kamera.updateTarget(targetParticle.getDisplayPosition());
  kamera.update();
  
  // UPDATE SELECTORS
  particleSelector.update(kamera);
  if (myFanSelection != null) {
    myFanSelection.update();
  }
  
  // RENDER
  particlesLayer.draw();
  
  inputDispatch.update();
  
  // PICKER / MOUSE
  Vector3f mouse = kamera.screenToModel(mouseX, mouseY);
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  beginCylindricalBillboardGL(mouse.x, mouse.y, mouse.z);
    float s = 5;
    gl.glPushMatrix();
      gl.glColor4f(1, 1, 1, 0.5);
      gl.glScalef(s, s, s);
      gl.glRotatef(35, 0, 0, 1);
      gl.glRotatef(-20, 1, 0, 0);
      gl.glRotatef(0.4*millis(), 0, 1, 0);
      gl.glTranslatef(0, -1, 0);
      glTriangle(gl);
      gl.glRotatef(35, 0, 1, 0);
      glTriangle(gl);
    gl.glPopMatrix();
  endBillboardGL();
  
  pgl.endGL();
  
  // UPDATE FPS
  myFpsTimer.update();
  
  // INFO LAYER
  myInfobox.print(
  + (int) myFpsTimer.seconds + " seconds\n"
  + (int) myFpsTimer.fpsRecent +  "fps (" + (int)(frameCount / myFpsTimer.seconds) + "avg)\n"
  + "particles: " + particles.size() + "\n"
//  + "target age:        " + nf(targetParticle.properTime, 3, 2) + " seconds\n"
//  + "target speed:      " + nf(targetParticle.velocity.magnitude, 1, 8) + " c\n"
//  + "target gamma:      " + nf(targetParticle.velocity.gamma, 1, 8) + "\n"
//  + "target position:   " + nfVec(targetParticle.position, 5) + "\n"
//  + "target displayPos: " + nfVec(targetParticle.getDisplayPositionVec(), 5)  
//  + "mouseX: " + mouseX + ", mouseY: " + mouseY + "\n"
  + "Controls: Arrows or W,A,S,D to Move; Right mouse button toggles camera rotation"
  );
  
  // GUI LAYER
  camera();
  imageMode(CORNERS);
  noLights(); //lights();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E7);
  controlP5.draw();
  
  // RESET CAMERA 
  kamera.commit();
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
      
      direction = direction + offset;
      
      if (prefs.getBoolean("1-D_control")) {
        direction = atan2( 0, cos(direction));
      }
      
      for (int i=0; i < targets.size(); i++) {
        
        if (prefs.getBoolean("energy_Conservation")) {
          energyNudge((Particle)targets.get(i), direction);
        }
        else {
          nudge((Particle)targets.get(i), direction, buttonPressure); 
        }
      }
    }
    else {
      buttonPressure *= buttonDecayFactor;
    }
    
    updateParticleDragging();
  }
  
  void energyNudge(Particle particle, float theta) {
    float energyAmt = 0.01*particle.mass*C*C;
    particle.emitEnergy(energyAmt, theta+PI);
    
    intervalSay(45, "energyNudge(): energyAmt: " + energyAmt);
  }
  
  void nudge(Particle particle, float theta, float amt) {
      
      float momentumScale = 0.05;
      //float momentumNudge = 0.0001 ;
      float momentumNudge = prefs.getFloat("momentumNudge");
      
      float v_mag = particle.velocity.magnitude;
      
      float p = particle.mass * particle.velocity.gamma * v_mag;
      
      float vx = targetParticle.velocity.vx;
      float vy = targetParticle.velocity.vy;
      
      float heading_initial = particle.velocity.direction;
      
      float angleDiff = heading_initial - theta;
      
      // Help user slow down at high speeds, quickly but smoothly
      if ((v_mag > 0.99999) && abs(abs(angleDiff)-PI) < TWO_PI/3.0) {
        theta = heading_initial + PI + angleDiff * (1.0 - v_mag);
        momentumScale = 0.10;
//        if (particle.impulseTotal > 0.1 * p) {
//          println("particle.impulseTotal > 0.1 : " + particle.impulseTotal);
//          momentumScale = 0.05;
//        }
      }
  
      float dp = amt * (momentumScale * p + momentumNudge);
  
      float dp_x = dp * cos(theta);
      float dp_y = dp * sin(theta);
      
      particle.propelSelf(dp_x, dp_y);
  }
  
  void updateParticleDragging() {
    
    if ( dragInProgress && mouseButton == LEFT
         && !particleSelector.isEmpty() && clickedParticle != null ) {
      
      Vector3f dragPointerDisplayPos = kamera.screenToModel(mouseX, mouseY);
      Vector3f dragPointerPos = Relativity.inverseDisplayTransform(targetParticle.velocity, dragPointerDisplayPos);
      
      Vector3f kameraPos = Relativity.inverseDisplayTransform(targetParticle.velocity, kamera.pos);
      
      Vector3f dragRayDirection = new Vector3f();
      dragRayDirection.sub(dragPointerPos, kameraPos);
      
      println("dragRayDirection: " + nfVec(dragRayDirection, 1));
      
      Line dragLine = new Line();
      dragLine.defineBySegment(kameraPos, dragPointerPos);
      
      println("kamera.pos: " + kamera.pos);
      println("kameraPos:  " + kameraPos);
      println("dragLine:   " + dragLine);
      
      Plane clickedPlane = clickedParticle.getSimultaneityPlane();
      println("clickedPlane: " + clickedPlane);
      
      Vector3f intersect = new Vector3f();
      clickedPlane.getIntersection(dragLine, intersect);
      
      Vector3f intersectDisplayPos = new Vector3f();
      Relativity.displayTransform(lorentzMatrix, intersect, intersectDisplayPos);
      
//      intervalSay(10, "intersect: " + nfVec(intersect, 1));
      
      pgl = (PGraphicsOpenGL)g;
      gl = pgl.beginGL();
        
        clickedParticle.drawHeadGL(gl, intersectDisplayPos);
        
        Frame draggedFrame = clickedParticle.headFrame.clone();
        ((DefaultFrame)draggedFrame).setPosition(intersect);
        
        myAxes.drawGL(gl, draggedFrame);
//        intervalSay(45, "drawingClickedParticle: " + nfVec(intersectDisplayPos, 1));
//        intervalSay(45, "clickedParticle: " + clickedParticle);
        
      pgl.endGL();
      
      Vector3f dragDirMarker = new Vector3f();
      dragDirMarker.scaleAdd(1, dragRayDirection, kameraPos);
      //dragDirMarker.scaleAdd(1, dragRayDirection, dragPointerDisplayPos);
      Vector3f dragDirMarkerDisplay = Relativity.displayTransform(targetParticle.velocity, dragDirMarker);
      
      Plane testPlane = new Plane();
      testPlane.setPoint(0,0,0);
      testPlane.setNormal(1,0,1);
      
      Line testLine = new Line();
      testLine.setPoint(0, 0, 20);
      testLine.setDirection(-1, 0, -1);
      
      Vector3f testIntersect = new Vector3f();
      testPlane.getIntersection(testLine, testIntersect);
      
      stroke(1, 1, 1, 1);
      color(1, 1, 1, 1);
      
      line(testIntersect.x, testIntersect.y, testIntersect.z, testLine.p.x, testLine.p.y, testLine.p.z);
      line(testIntersect.x, testIntersect.y, testIntersect.z, 0, 0, 0);
      
      line(testPlane.p.x, testPlane.p.y, testPlane.p.z, 
           testPlane.p.x + testPlane.n.x, testPlane.p.y + testPlane.n.y, testPlane.p.z + testPlane.n.z);
      
      noStroke();
      
      HashMap debugMarkersMap = new HashMap();
      debugMarkersMap.put("intersect", intersect);
      debugMarkersMap.put("intersectDisplayPos", intersectDisplayPos);
      debugMarkersMap.put("dragPointerDisplayPos", dragPointerDisplayPos);
      
      pgl = (PGraphicsOpenGL)g;
      gl = pgl.beginGL();
      
      for (Iterator keyIter = debugMarkersMap.keySet().iterator(); keyIter.hasNext(); ) {
        String label = (String) keyIter.next();
        Vector3f labelPos = (Vector3f) debugMarkersMap.get(label);
        myLabelor.drawLabelGL(gl, label, labelPos, 0.5);
      }
      
      pgl.endGL();
      
      // DRAW DEBUG MARKERS
      Vector3f[] debugMarkers = new Vector3f[] {
//        testIntersect,
        
//        kamera.pos,              // CORRECT
//        dragPointerDisplayPos,   // CORRECT
        intersect,
        intersectDisplayPos,
//        dragDirMarkerDisplay,
      };
      
      for (Iterator valsIter = debugMarkersMap.values().iterator(); valsIter.hasNext(); ) {
        Vector3f drawPos = (Vector3f) valsIter.next();
        drawSphere(drawPos, 1f);
//        drawSphere(debugMarkers[i], 1f);
      }
    }
  }
}

void drawSphere(Vector3f pos, float radius) {
  pushMatrix();
    translate(pos.x, pos.y, pos.z);
    sphere(radius);
  popMatrix();
}

/*
class ParticleDragger {
  
  boolean dragStarted;
  float millisLastClick;
  Particle clickedParticle;
  Vector3f dragPointerIntersect;
  Vector3f dragOffset;
}
*/
Particle clickedParticle;

boolean isFanSelectionOpen() {
  return labelSelector.selection.contains(myFanSelection);
}

void openFanSelection(Particle pickedParticle) {
  SelectableLabel[] labels = new SelectableLabel[] {
    new SelectableLabel("menuDummy1", pickedParticle.getDisplayPositionVec()),
    new SelectableLabel("menuDummy2", pickedParticle.getDisplayPositionVec()),
    new SelectableLabel("menuDummy3", pickedParticle.getDisplayPositionVec()),
    new SelectableLabel("menuDummy4", pickedParticle.getDisplayPositionVec()),
    new SelectableLabel("menuDummy5", pickedParticle.getDisplayPositionVec()),
  };
  
  myFanSelection = new FanSelection( pickedParticle, labels);
  labelSelector.addToSelectables(myFanSelection.getSelectableLabels());
  labelSelector.selection.add(myFanSelection);
}

void mousePickedParticle(Particle pick) {
  if (mouseButton == RIGHT) {
    openFanSelection(pick);
  }
  else if (mouseButton == LEFT) {
    particleSelector.invertSelectionStatus(pick);
  }
}

void mousePressedOnBackground() {
  if (mouseButton == LEFT) {
    particleSelector.clear();
  }
  else if (mouseButton == RIGHT) {
    MOUSELOOK = !MOUSELOOK;
    
    if (MOUSELOOK) {
      cursor(MOVE);
    }
    else {
      cursor(ARROW);//noCursor();
    }
  }
}

void mousePressedOnScene() {
  
  Selectable pickedParticle = (Particle) particleSelector.pickPoint(kamera, mouseX, mouseY);
  Selectable pickedLabel = labelSelector.pickPoint(kamera, mouseX, mouseY);
  Selectable pick = (pickedLabel != null) ? pickedLabel : pickedParticle;
    
  if (pickedParticle == null && pickedLabel == null) {
    mousePressedOnBackground();
  }
  else if (isFanSelectionOpen() && mouseButton == RIGHT) {
    labelSelector.drop(myFanSelection.getSelectableLabels());
  }
  else if (pickedLabel != null) {
    //mousePickedLabel(pickedLabel);
  }
  else if (pickedParticle != null) {
    mousePickedParticle((Particle)pickedParticle);
  }
}

void mousePressed() {
  
  if (controlP5.window(this).isMouseOver()) {
    return;
  }
  else {
    mousePressedOnScene();
  }
}

void mouseReleased() {
  
  dragInProgress = false;
}

boolean dragInProgress;

void mouseDragged() {
  
  if (!dragInProgress) {
      dragInProgress = true;
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
  switch (keyCode) {
    case UP : INPUT_UP = true; break;
    case DOWN : INPUT_DOWN = true; break;
    case LEFT : INPUT_LEFT = true; break;
    case RIGHT : INPUT_RIGHT = true; break;
  }
  
  if (key == ' ') {
    int i = (int) random(prefs.getInteger("PARTICLES"));
    targetParticle = (Particle) particles.get(i);
    addTarget((Particle)particles.get(i));
  }
  else if (key == '`') {
    particleSelector.clear();
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
  switch (keyCode) {
    case UP : INPUT_UP = false; break;
    case DOWN : INPUT_DOWN = false; break;
    case LEFT : INPUT_LEFT = false; break;
    case RIGHT : INPUT_RIGHT = false; break;
  }
}

