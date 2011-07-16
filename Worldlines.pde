// Worldlines
// tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;

import java.util.*;
import javax.vecmath.*;
import java.awt.geom.Rectangle2D;
import java.awt.Font;
import java.awt.FontFormatException;

import com.sun.opengl.util.texture.*;
import com.sun.opengl.util.BufferUtil;
import java.nio.ByteBuffer;
import java.nio.Buffer;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Matrix3f lorentzMatrix;
Matrix3f inverseLorentzMatrix;

Scene topScene;
Scene primaryScene;
InfolayerScene infolayerScene;

List scenes;
List particles;
List simultIntersections;
List measurables;

Particle targetParticle;
AxesSettings originAxesSettings, targetAxesSettings;

ArrayList targets;
ArrayList emissions;
ArrayList rigidBodies;

Selector particleSelector;
Selector labelSelector;
Selector intersectionSelector;

FanSelection myFanSelection;

DefaultFrame originFrame;
DefaultFrame restFrame;

ParticlesLayer particlesLayer;
InputDispatch inputDispatch;

Axes myAxes;

float C = 1.0;

FpsTimer myFpsTimer;

String PRIMARY_SCENE = "LengthContractionScene";

// SCENES LISTED IN SCENE MENU
String[] menuClassNames = new String[] {
  "AxesScene",
  "TwinParadoxScene",
  "MultiTwinScene",
  "LengthContractionScene",
  "BellsSpaceShipScene",
  "UniformParticleScene",
//  "RandomParticleScene",
//  "PolygonParticleScene",
//  "PhotonScene"
};

// GUI Control Vars
public int PARTICLES = 45; //16;

public int TARGET_COLOR = #F01B5E;
public int PARTICLE_COLOR = #1B83F0;

public int ACTION_COLOR = 0xFF86FF74;
public int ACTION_COLOR_CONTRAST = 0xFF000000;

// Data Files
String PARTICLE_IMAGE = "particle.png";
String bundledFont = "VeraMono.ttf";

int FONT_SIZE = 14;

ControlP5 controlP5;

void setup() {
  
  //size(800, 480, OPENGL);
  //size(900, 540, OPENGL);
  size(1000, 580, OPENGL);
  //size(1280, 900, OPENGL);
  
  frameRate(45);
  
  runTests();
  
  restart();
}

VTextRenderer myVTextRenderer, infobarVTextRenderer;
Labelor myLabelor;

static ControlMap prefs;

void controlEvent(controlP5.ControlEvent event) {
  prefs.handleControlEvent(event);
}

// CONTROLP5 CALLBACK (For "Play/Pause" button)
public void playStatus() {
  StateControl c = (StateControl) prefs.getControl("playStatus");
  c.setState( (c.getState() == "paused") ? "playing" : "paused" );
  
  Dbg.say("playStatus(): state -> " + c.getState());
  Dbg.say("playStatus(): label -> " + c.getLabel());
}

// CONTROLP5 CALLBACK (For "Random" button)
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
  panel.putInteger("PARTICLES", PARTICLES, 0, max(25, PARTICLES*5));
  panel.putInteger("TARGETS", 3, 1, PARTICLES);
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
  panel.putFloat("timestep", 10, 0, 20);
  panel.putBoolean("PROPERTIME_SCALING", true);
  panel.putBoolean("toggle_Spatial_Transform", false);
  panel.putBoolean("toggle_Temporal_Transform", false);
  panel.putBoolean("1-D_control", false);
  panel.putBoolean("show_Rigid_Bodies", true);
  panel.putBoolean("use_Emissions", false);
  
  targetAxesSettings = new AxesSettings();
  originAxesSettings = new AxesSettings();
  targetAxesSettings.setAxesLabelsVisible(true);
  
  panel.putBoolean("show_Target_Axes_Grid", true).addUpdater(
    new AxesSettingsVisibilityUpdater(targetAxesSettings));
  panel.putBoolean("show_Origin_Axes_Grid", false).addUpdater(
    new AxesSettingsVisibilityUpdater(originAxesSettings));
  panel.putBoolean("show_Particle_Clock_Ticks", true);
  
  // DEBUG PANEL
  ControlPanel debugPanel = new ControlPanel("debug");
  panel = debugPanel;
  panel.putInteger("maxEmissions", 50, 0, 500);
  panel.putFloat("backgroundColorHue", 0.65f);         // 0.59 - 0.65
  panel.putFloat("backgroundColorSaturation", 0.60f);  // 0.48 - 0.70
  panel.putFloat("backgroundColorBrightness", 0.23f);  // 0.17 - 0.28
  panel.putFloat("cauchyGamma", 1, 0, 4);
  panel.putFloat("momentumNudge", 0.003, 0, 1);
  panel.putBoolean("energy_Conservation", false);
  panel.putFloat("INPUT_RESPONSIVENESS", 0.13);
  
  // GRAPHICS PANEL
  ControlPanel graphicsPanel = new ControlPanel("graphics");
  panel = graphicsPanel;
  panel.putFloat("PARTICLE_SIZE", 2.5, 0, 10);  // 1.3 - 2.5
  panel.putFloat("LIGHTING_WORLDLINES", 0.8);
  panel.putFloat("STROKE_WIDTH", 2, 0, 8);
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
  
  ControlP5 theControlP5 = new ControlP5(this);
  theControlP5.setAutoDraw(false);
  //theControlP5.setColorForeground(#093967);
  
  thePrefs.buildControlP5(theControlP5);
  
  return theControlP5;
}

void restart() {
  
  // BUILD CONTROL PANELS
  ControlPanel[] controlPanels = buildControlPanels();
  
  // BUILD PREFERENCES
  prefs = buildPrefs(controlPanels);
  
  // NON-GUI PREFS
  prefs.put("particleImagePath", "particle_hard.png");
  prefs.put("particleClockTickImagePath", "particle_clock_tick.png");
  prefs.put("selectedParticleImagePath", "particle_reticle.png");
  prefs.put("startPosWeight", "cauchy");
  
  // FONT
  byte[] fontBytes = loadBytes(bundledFont);
  int fontSize = (int)(0.025 * height);
  Font font = loadFont(fontBytes, fontSize);
  
  // TEXT RENDERER
  myVTextRenderer = new VTextRenderer(font.deriveFont(40f), (int)(1*fontSize));
  
  // INFOBOX + LABELOR
  myLabelor = new Labelor();
  
  kamera = new Kamera();
  
  // SCENE OBJECTS
  targets = new ArrayList();
  particles = new ArrayList();
  emissions = new ArrayList();
  rigidBodies = new ArrayList();
  simultIntersections = new ArrayList();
    
  // SCENES
  scenes = new ArrayList();
  topScene = new Scene();
  
  // SELECTABLES
  myFanSelection = null;
  labelSelector = new Selector();
  particleSelector = new Selector(particles);
  intersectionSelector = new Selector();
  
  // INIT LORENTZ FOR PARTICLE CREATION
  Vector3f targetPos = new Vector3f();
  Velocity targetVelocity = new Velocity(0f, 0f);
  
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetVelocity);
  inverseLorentzMatrix = Relativity.getInverseLorentzTransformMatrix(targetVelocity);
  
  // TARGET PARTICLES
  targetParticle = new Particle(targetPos, targetVelocity);
  targetParticle.headFrame.axesSettings = targetAxesSettings;
  
  // FRAMES
  originFrame = new DefaultFrame();
  originFrame.axesSettings = originAxesSettings;
  originAxesSettings.setAllVisibility(false);
  originAxesSettings.setAxesVisible(true);
  
  restFrame = new DefaultFrame();
  restFrame.setVelocity(0,0);
  
  // PARTICLES LAYER
  particlesLayer = new ParticlesLayer(
    particles,
    prefs.getString("particleImagePath"),
    kamera,
    particleSelector.selection
  );
  
  // INPUT
  inputDispatch = new InputDispatch(targets);
  
  myAxes = new Axes();
  myFpsTimer = new FpsTimer();
  
  // PRIMARY SCENE
  primaryScene = buildScene(PRIMARY_SCENE);
  addScene(primaryScene);
  
  // CONTROLP5
  controlP5 = buildControlP5(prefs);
  
  // Load any prefs defined by the PrimaryScene
  for (Iterator iter=primaryScene.scenePrefs.keySet().iterator(); iter.hasNext(); ) {
    String name = (String) iter.next();
    Object value = primaryScene.scenePrefs.get(name);
    
    // If a control, just want the value represented
    if (value instanceof Control) {
      value = ((Control) value).getValue();
    }
    Dbg.say("primaryScene pref: " + name + ", value: " + value);
    Dbg.say("   updatedControl: " + name);
    
    // Sync prefs controlmap
    prefs.getControl(name).setValue(value);
    
    // Hack to sync controlP5
    controlP5.controller(name).setValue(parseForControlP5(value));
  }
  
  // MENULAYER
  MenuLayerScene menuLayerScene = new MenuLayerScene();
  addScene(menuLayerScene);
  
  // INFOLAYER SCENE
  infolayerScene = new InfolayerScene(font);
  addScene(infolayerScene);
  
  prefs.notifyAllUpdaters();
}

// TRAPEZOID VERTICES CONSTRUCTOR
Vector3f[] buildTrapezoidVertices() {
  return new Vector3f[] {
    new Vector3f(+10, +2.5, 0),
    new Vector3f(+10, -2.5, 0),
    new Vector3f(-10, -10, 0),
    new Vector3f(-10, +10, 0),
  };
}

// DEFAULT RIGID BODY VERTICES
Vector3f[] buildRigidBodyVertices() {
  return buildTrapezoidVertices();
}

// RIGID BODY CONSTRUCTOR
List buildRigidBodiesAt(Vector3f[] bodyVertices, Collection theParticles) {
  List theBodies = new ArrayList();
  
  for (Iterator iter=theParticles.iterator(); iter.hasNext(); ) {
    Particle p = (Particle) iter.next();
    RigidBody rb = new RigidBody(p, bodyVertices);
    theBodies.add(rb);
  }
  return theBodies;
}

// PARTICLE CONSTRUCTOR
List buildParticlesAt(Vector3f[] positions, Velocity theVelocity) {
  List theParticles = new ArrayList();
  
  for (int i=0; i < positions.length; i++) {
    Particle p = new Particle(positions[i], theVelocity);
    theParticles.add(p);
  }
  return theParticles;
}

// MANAGEMENT - SCENE, PARTICLE, EMISSION, RIGIDBODIES
void addScene(Scene s) {
  if (s == null) { return; }
  
  topScene.subScenes.add(s);
  
  if (!scenes.contains(s)) {
    scenes.add(s);
  }
  
  if (s instanceof ParticleScene) {
    addParticles( ((ParticleScene)s).getAllParticles() );
  }
}

void addParticles(Collection theParticles) {
  if (theParticles == null) { return; }
  
  for (Iterator iter=theParticles.iterator(); iter.hasNext(); ) {
    Particle p = (Particle) iter.next();
    addParticle(p);
  }
}

void addParticle(Particle p) {
  if (p == null) { return; }
  
  if (!particles.contains(p)) {
    particles.add(p);
  }
  addSelectable(p);
  
  PathPlaneIntersection intersection = new PathPlaneIntersection(p, targetParticle);
  simultIntersections.add(intersection);
  intersectionSelector.selectables.add(intersection);
}

void addSelectable(Particle p) {
  
  if (!particleSelector.selectables.contains(p)) {
    particleSelector.addToSelectables(p);
  }
}

void addTargets(List theParticles) {
  
  for (Iterator iter=theParticles.iterator(); iter.hasNext(); ) {
    Particle p = (Particle) iter.next();
    addTarget(p);
  }
}

void addTarget(Particle p) {
  if (p == null) { return; }
  
  addParticle(p);
  if ( !targets.contains(p) ) {
    targets.add(p);
  }
  p.setFillColor(TARGET_COLOR);
}

/** Target a different particle instead of one which is currently targeted. */
void swapTargetStatus(Particle targeted, Particle toTarget) {
  
  if (targets.contains(targeted)) {
    targets.remove(targeted);
    targets.add(toTarget);
  }
  
  if (targeted == targetParticle) {
    makeTargetParticle(toTarget);
  }
}

void swapSelectionStatus(Particle selected, Particle toSelect) {
  if (particleSelector.contains(selected)) {
    particleSelector.remove(selected);
    particleSelector.add(toSelect);
  }
}

void addEmission(Particle e) {
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

void addRigidBody(RigidBody rb) {
  if (rb == null) { return; }
  
  rigidBodies.add(rb);
}

void addRigidBodies(List theBodies) {
  
  for (Iterator iter=theBodies.iterator(); iter.hasNext(); ) {
    RigidBody rb = (RigidBody) iter.next();
    addRigidBody(rb);
  }
}

void draw() {  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  gl.glLineWidth(prefs.getFloat("STROKE_WIDTH"));
  
  pgl.endGL();
  
  // SCENE PREP
  colorMode(HSB, 1.0f); 
  color c = color(
    prefs.getFloat("backgroundColorHue"),
    prefs.getFloat("backgroundColorSaturation"),
    prefs.getFloat("backgroundColorBrightness")
  );
  
  background(c);
  colorMode(RGB, 1.0f);
  
  // UPDATE SCENE
  for (Iterator iter=scenes.iterator(); iter.hasNext(); ) {
    Scene scene = (Scene)iter.next();
    scene.update();
  }
  
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
  intersectionSelector.update(kamera);
  
  if (myFanSelection != null) {
    myFanSelection.update();
  }
  
  // RENDER
  particlesLayer.draw();
  
  inputDispatch.update();
  
  // UPDATE FPS
  myFpsTimer.update();
  
  // PICKER / MOUSE
  drawMouse();
  
  // SCENE-SPECIFIC DRAW ROUTINES
  drawScenes();
  
  // GUI: PREPARE BLEND MODE
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
    gl.glEnable(GL.GL_BLEND);
    gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  pgl.endGL();
  
  // GUI: PREPARE CAMERA
  camera();
  imageMode(CORNERS);
  noLights();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E7);
  
  // DRAW GUI
  controlP5.draw();
  
  // RESET CAMERA
  kamera.commit();
}

void drawScenes() {
  
  Collection allScenes = new ArrayList();
  topScene.getAllScenes(allScenes);
  
  Iterator iter = allScenes.iterator();
  
  while ( iter.hasNext() ) {
    Scene scene = (Scene) iter.next();
    scene.draw();
  }
}

void drawMouse() {
  Vector3f mouse = kamera.screenToModel(mouseX, mouseY);
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  beginCylindricalBillboardGL(mouse.x, mouse.y, mouse.z);
    float s = 5;
    gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
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
}

