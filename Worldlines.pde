// Worldlines
// tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
//import javax.media.opengl.glu.GLU;
import controlP5.*;
import javax.vecmath.*;
import geometry.*;

import java.awt.geom.Rectangle2D;
import org.apache.commons.math.*;

import com.sun.opengl.util.texture.*;
import com.sun.opengl.util.BufferUtil;
import java.nio.ByteBuffer;
import java.nio.Buffer;

PGraphicsOpenGL pgl;
GL gl;
//GLU glu;

Kamera kamera;

Matrix3f lorentzMatrix;

ArrayList particles;
Particle targetParticle;
ArrayList targets;
ArrayList emissions;

Selector particleSelector;

DefaultFrame restFrame;

ParticleUpdater particleUpdater;

ParticlesLayer particlesLayer;
InputDispatch inputDispatch;

Axes myAxes;
ParticleGrid particleGrid;

float C = 1.0;
float timeDelta = 0.2;

// GUI Control Vars
public int PARTICLES = 50;

public int TARGET_COLOR = #F01B5E;
public int PARTICLE_COLOR = #1B83F0;

public void playStatus() {
  StateControl c = (StateControl) prefs.getControl("playStatus");
  c.setState( (c.getState() == "paused") ? "playing" : "paused" );
  
  Dbg.say("playStatus(): state -> " + c.getState());
}

public void randomize() {
  
  String[] floatLabels = new String[] {
    "START_POS_DISPERSION",
    //"START_POS_XY_RATIO",
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

  //TARGETS = (int)(random(1, PARTICLES/3));
  setup();
}

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

String lastControlEventLabel = "";
float lastControlEventValue = 0;

void setup() {
  size(900, 540, OPENGL);
  //size(1280, 900, OPENGL);
  
  frameRate(45);
  //hint(DISABLE_DEPTH_SORT);
  
  restart(); //initScene();
}

VTextRenderer myVTextRenderer;
Infobox myInfobox;
Labelor myLabelor;

ControlPanel[] controlPanels;
ControlMap prefs;

void controlEvent(controlP5.ControlEvent event) {
  prefs.handleControlEvent(event);
}

//void initScene() {
void restart() {
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
  panel.putInteger("TARGETS", 3, 1, PARTICLES);
  panel.putFloat("START_POS_DISPERSION", 2.6, 0, 4);
  panel.putFloat("START_POS_X_SCALE", 2.6, 0, 3);
  panel.putFloat("START_POS_Y_SCALE", 2.6, 0, 3);
  //panel.putFloat("START_POS_XY_RATIO", 1, 0.5, 2);
  panel.putFloat("cauchyGamma", 1, 0, 4);
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
  panel.putBoolean("TOGGLE_TIMESTEP_SCALING", true);
  panel.putBoolean("toggleSpatialTransform", true);
  panel.putBoolean("toggleTemporalTransform", true);
  panel.putBoolean("1-D_control", true);
  panel.putBoolean("useEmissions", true);
  //panel.putBoolean("showAxesGrid", false);
  panel.putBoolean("showTargetAxesGrid", true);
  panel.putBoolean("showTargetAxesLabels", true);
  panel.putBoolean("showAllAxesGrid", false);
  panel.putBoolean("showAllAxesLabels", false);
  
  // DEBUG PANEL
  ControlPanel debugPanel = new ControlPanel("debug");
  panel = debugPanel;
  //panel.putBoolean("useGL", true);
  panel.putFloat("fov", 60, 0, 180);
  panel.putFloat("backgroundColorHue", 0.65f);// 0.59);//
  panel.putFloat("backgroundColorSaturation", 0.65f);// 0.70);//
  panel.putFloat("backgroundColorBrightness", 0.17f);// 0.31);//
  panel.putFloat("momentumNudge", 0.003, 0, 1);
  panel.putFloat("INPUT_RESPONSIVENESS", 0.13);
  panel.putInteger("maxEmissions", 50, 0, 500);
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
  
  if (controlPanels == null) {
    controlPanels = new ControlPanel[] {
      setupPanel,
      mainPanel,
      debugPanel,
      graphicsPanel
    };
  }
  
  // PREFERENCES
  prefs = new ControlMap(controlPanels);
  
  prefs.put("particleImagePath", "particle_hard.png");//"particle_cushioned_core.png");
  prefs.put("selectedParticleImagePath", "particle_reticle.png");
  prefs.put("startPosWeight", "cauchy");
  
  byte[] fontBytes = loadBytes(bundledFont);
  int fontSize = (int)(0.025 * height);
  println(fontSize);
  
  myInfobox = new Infobox(fontBytes, fontSize);
  
  Font font = myInfobox.loadFont(fontBytes);
  myVTextRenderer = new VTextRenderer(font.deriveFont((float)40), (int)(1*fontSize));
  myLabelor = new Labelor();
  
  int numGlobalControls = 0;
  int numTabControls = 0;
  
  int bWidth = 25;
  int bHeight = 20;
  int bSpacingY = bHeight + 15;
  int sliderWidth = bWidth*5;
  
  int xOffsetGlobal = 10;
  
  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
  controlP5.setColorForeground(#093967);
  
  // BUILD CONTROLP5
  for (int panelIndex=0; panelIndex<controlPanels.length; panelIndex++) {
    
    ControlPanel thePanel = controlPanels[panelIndex];
    String tabName = thePanel.name;
    String tabLabel = thePanel.label;
    
    controlP5.addTab(tabName).setLabel(tabLabel);
    
    boolean defaultValue = false;
    int xPadding = 10;
    int yPadding = 15;
    
    int toggleWidth = 20;
    int toggleHeight = 20;
    
    int yOffsetGlobal = numGlobalControls*bSpacingY + bHeight;
    
    int xOffset = xOffsetGlobal;
    int yOffset = yPadding + yOffsetGlobal;
    
    for (int i=0; i<thePanel.controls.size(); i++) {
      Control control = (Control) thePanel.controls.get(i);
      
      Object prefValue = control.getValue();
      String name = control.getName();
      String label = control.getLabel();
      
      String className = prefValue.getClass().getName();
      println("Controller for control('" + label + "' : " + prefValue + ") (" + className +")");
      
      if (prefValue instanceof java.lang.Boolean) {
        
        controlP5.addToggle(label, (Boolean) prefValue, xOffset, yOffset, toggleWidth, toggleHeight).moveTo(tabName);
        //Toggle t = (Toggle) controlP5.controller(keyName);
        
        yOffset += toggleHeight + yPadding;
      }
      else if (prefValue instanceof java.lang.Float) {
        
        float minValue = ((FloatControl)control).min;
        float maxValue = ((FloatControl)control).max;
        
        controlP5.addSlider(label, minValue, maxValue, (Float) prefValue, xOffset, yOffset, sliderWidth, bHeight).moveTo(tabName);
        yOffset += bHeight + yPadding;
      }
      else if (prefValue instanceof java.lang.Integer) {
        
        float minValue = ((IntegerControl)control).min;
        float maxValue = ((IntegerControl)control).max;
        
        controlP5.addSlider(label, minValue, maxValue, (Integer)prefValue, xOffset, yOffset, sliderWidth, bHeight).moveTo(tabName);
        yOffset += bHeight + yPadding;
      }
      else if (control instanceof ButtonControl) {
        
        controlP5.addButton(label, 0, xOffset, yOffset, 2*bWidth, bHeight).moveTo(tabName);
        yOffset += bHeight + yPadding;
      }
      else if (control instanceof StateControl) {
        
        controlP5.addButton(name, 0, xOffset, yOffset, 2*bWidth, bHeight).moveTo(tabName);
        controlP5.Button b = (controlP5.Button) controlP5.controller(name);
        b.setLabel(label);
        yOffset += bHeight + yPadding;
      }
    }
  }
  
  Velocity targetVelocity = new Velocity(1E-7f,0f);
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetVelocity);
  
  // SCENE OBJECTS
  //targetParticle = new Particle(targetPos, targetVel);
  //addTarget(targetParticle);
  targetParticle = new Particle();
  targetParticle.setVelocity(targetVelocity.vx, targetVelocity.vy);
  targetParticle.setPosition(0, 0, 0);
  targetParticle.setFillColor(color(#F01B5E));
  
  particles = new ArrayList();
  particles.add(targetParticle);
  
  for (int i=1; i<prefs.getInteger("PARTICLES"); i++) {
    
    //float xScale = pow(10, prefs.getFloat("START_POS_DISPERSION_X"));
    //float yScale = pow(10, prefs.getFloat("START_POS_DISPERSION_Y"));
    
    float xScale = prefs.getFloat("START_POS_X_SCALE");
    float yScale = prefs.getFloat("START_POS_Y_SCALE");
    
    float x, y;
    
    float rScale = pow(10, prefs.getFloat("START_POS_DISPERSION"));
    //float xyRatio = prefs.getFloat("START_POS_XY_RATIO");
    
    if (prefs.getString("startPosWeight") == "cauchy") {
      float cauchyGamma = prefs.getFloat("cauchyGamma");//0.1;
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
  
  println("target pos: " + targetParticle.position.x + ", " + targetParticle.position.y);
  println("target direction: " + targetParticle.velocity.direction);
  println("target magnitude: " + targetParticle.velocity.magnitude);
  println("target gamma:     " + targetParticle.velocity.gamma);
  
  targets = new ArrayList();
  float numTargets = prefs.getInteger("TARGETS");
  for (int i=0; i < numTargets; i++) {
    Particle p = (Particle) particles.get(i);
    addTarget(p);
    
    float theta = TWO_PI * ((float)i) / numTargets;
    float r = 5 * numTargets;
    Dbg.say("theta/TWO_PI, r: " + theta/TWO_PI + " " + r);
    //Vector3f pos = new Vector3f(1 + random(-1, 1) * cos(theta), 1 + random(-1, 1) * sin(theta), 0);
    Vector3f pos = new Vector3f(cos(theta)-1, sin(theta), 0);
    Dbg.say("target[" + i + "].pos: " + pos);
    pos.scaleAdd(r, pos, targetParticle.getPositionVec());
    p.setPosition(pos);
  }
  
  emissions = new ArrayList();
  
  kamera = new Kamera();
  kamera.setFov(prefs.getFloat("fov"));
  
  restFrame = new DefaultFrame();
  restFrame.setVelocity(0,0);
  
  particleSelector = new Selector(particles, targets);
  particlesLayer = new ParticlesLayer(particles, prefs.getString("particleImagePath"), kamera, particleSelector.selection);
  
  inputDispatch = new InputDispatch(targets);
  
  particleGrid = new ParticleGrid(3*50, 5*1000);
  myAxes = new Axes((Frame)targetParticle);
  
  Velocity restFrameVel = new Velocity(0, 0);
  
  // THREADING
  particleUpdater = new ParticleUpdater(targetParticle, particles);
  //particleUpdater.start();
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

void addTarget(Particle p){
  targets.add(p);
  p.velocity.set(targetParticle.velocity);
  p.setFillColor(TARGET_COLOR);
}

void addEmission(Particle e){
  if ( prefs.getBoolean("useEmissions") ) {
    
    emissions.add(e);
    particles.add(e);
    e.setFillColor(color(0, 1, 0));
    
    if (emissions.size() > prefs.getInteger("maxEmissions")) {
      Particle oldEmission = (Particle) emissions.remove(0);
      particles.remove(oldEmission);
    }
  }
}
/*
float NEAR = -1;
float FAR = 10000;

//void beginOrthoGL(GL gl) {
void orthoGL(GL gl) {
  //GLDrawable glDrawable = GLContext.getCurrent().getGLDrawable();
  //gl.glMatrixMode(GL.GL_PROJECTION);   //select the Projection matrix
  //gl.glPushMatrix();                   //save the current projection matrix
  //gl.glLoadIdentity();                 //reset the current projection matrix to creates a new Orthographic projection
  //Creates a new orthographic viewing volume
  //gl.glOrtho(0, glDrawable.getWidth(), 0, glDrawable.getHeight(), NEAR, FAR);
  //gl.glOrtho(0, width, 0, height, NEAR, FAR);
  
  //glu.gluPerspective(90.0, (float) width/ (float)height, -1.0, 2000.0);
  //glu = ((PGraphicsOpenGL)g).glu;
  gl.glMatrixMode(GL.GL_MODELVIEW);
  gl.glLoadIdentity();
  intervalSay(45, "kamera.target: " + kamera.target);
  glu.gluLookAt(
    //kamera.pos.x, kamera.pos.y, kamera.pos.z,
    //kamera.target.x, kamera.target.y, kamera.target.z + 100,
    kamera.target.x, kamera.target.y, 100,//kamera.target.z + 100,
    //kamera.target.x, kamera.target.y, kamera.target.z,
    0, 0, kamera.target.z,
    //-kamera.up.x, -kamera.up.y, -kamera.up.z
    0, 1, 0
    );
}
*/
void draw() {
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  //glu = ((PGraphicsOpenGL)g).glu;  
  //glu = new GLU();
  
  gl.glScalef(1,1,1);
  
  gl.glEnable(GL.GL_BLEND);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  gl.glLineWidth(prefs.getFloat("STROKE_WIDTH"));
  
  //orthoGL(gl);
  pgl.endGL();
  
  // SCENE PREP
  //color c = #000020; //#3473F7;
  colorMode(HSB, 1.0f); //c = color((frameCount * 0.5)%255, 100, 75, 255);
  color c = color(
    prefs.getFloat("backgroundColorHue"),
    prefs.getFloat("backgroundColorSaturation"),
    prefs.getFloat("backgroundColorBrightness")
  );
  background(c); //background((Float)prefs.get("backgroundColor"));
  colorMode(RGB, 1.0f);
  //directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, 0.5, -0.5);
  //directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, -0.5, -0.5);
  prefs.getFloat("STROKE_WIDTH");
  
  // UPDATE SCENE
  inputDispatch.update();
  particleSelector.update(kamera);
  
  float dilationFactor =  prefs.getBoolean("TOGGLE_TIMESTEP_SCALING") ? targetParticle.velocity.gamma : 1.0;
  float dt = timeDelta * dilationFactor;
  
  if (prefs.getState("playStatus") == "paused") {
    dt = 0;
  }
  
  particleUpdater.dt = dt;
  
  targetParticle.update(dt);
  
  //Relativity.loadFrame(targetParticle);
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetParticle.velocity);
  Relativity.TOGGLE_SPATIAL_TRANSFORM = prefs.getBoolean("toggleSpatialTransform");
  Relativity.TOGGLE_TEMPORAL_TRANSFORM = prefs.getBoolean("toggleTemporalTransform");
  
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
  kamera.update(timeDelta);
  
  // RENDER
  particlesLayer.draw(); //particleGrid.draw(targetParticle.xyt);
  
  // PICKER
  Vector3f mouse = kamera.screenToModel(mouseX, mouseY);
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  beginCylindricalBillboardGL(mouse.x, mouse.y, mouse.z);
    float s = 5;
    // MOUSE
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
  
  //myLabelor.drawLabelGL(gl, "mouse", mouse);
  //myLabelor.drawLabelGL(gl, "targetParticle", targetParticle.getDisplayPositionVec(), false);
  
  pgl.endGL();
  
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
  + "particles: " + particles.size() + "\n"
  //+ "targetParticle.pos.z: " + nf(targetParticle.position.z, 3, 2) + " seconds\n"
  //+ "kamera.target.x:      " + nf(kamera.target.x, 3, 2) + " seconds\n"
  + "target age:        " + nf(targetParticle.properTime, 3, 2) + " seconds\n"
  + "target speed:      " + nf(targetParticle.velocity.magnitude, 1, 8) + " c\n"
  + "target gamma:      " + nf(targetParticle.velocity.gamma, 1, 8) + "\n"
  + "target position:   " + nfVec(targetParticle.position, 5) + "\n"
  + "target displayPos: " + nfVec(targetParticle.getDisplayPositionVec(), 5)
  //+ "Controls: W,A,S,D to move; Right mouse button toggles camera rotation"
  );
  
  // GUI LAYER
  imageMode(CORNERS);
  camera();
  noLights(); //lights();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E7);
  
  controlP5.draw();
}

class ParticlesLayer {
  ArrayList particles;
  ArrayList selection;
  
  PImage particleImage;
  Kamera kamera;
  
  Texture particleTexture;
  Texture selectedParticleTexture;
  
  int[] textures = new int[3];
    
  ParticlesLayer (ArrayList particles, String particleImagePath, Kamera kamera, ArrayList selection) {
    this.particles = particles;
    this.selection = selection;
    
    this.kamera = kamera;
    this.particleImage = loadImage(particleImagePath);
    //this.particleTexture = loadTexture(particleImagePath);
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    this.particleTexture = loadTextureFromStream(openStream(particleImagePath));
    //println("prefs.getString('selectedParticleImagePath'): " + prefs.getString("selectedParticleImagePath"));
    this.selectedParticleTexture = loadTextureFromStream(openStream(prefs.getString("selectedParticleImagePath")));
    //loadTextureGL(openStream(particleImagePath));
    pgl.endGL();
  }
  
  void loadTextureGL(InputStream textureStream){
    
    TextureData textureData = null;
    //dumpStreamBytes(textureStream, 32);
    try {
      textureData = TextureIO.newTextureData(textureStream, true, TextureIO.PNG);
      //texture = TextureIO.newTexture(textureStream, false, TextureIO.PNG);
    }
    catch(Exception e) {
      println("Error loading textureData: " + e);
    }
    
    int imgWidth = textureData.getWidth();
    int imgHeight = textureData.getHeight();
    int bytesPerPixel = 4;
    
    Buffer textureBuffer = textureData.getBuffer();
    
    gl.glGenTextures(1, textures, 0);
    gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]);
    gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_REPEAT);
    gl.glTexImage2D(
      GL.GL_TEXTURE_2D,
      0,
      GL.GL_RGBA,
      imgWidth,
      imgHeight,
      0,
      GL.GL_UNSIGNED_BYTE,//GL.GL_INT,//GL.GL_BYTE,//
      GL.GL_RGBA,
      textureBuffer
    );
    
    if (textureBuffer != null) {
      println("textureBuffer.toString(): " + textureBuffer.toString());
    }
    else {
      println("textureBuffer was null");
    }
  }
  
  Texture loadTextureFromStream(InputStream textureStream){
    
    Texture texture = null;
    
    try {
      texture = TextureIO.newTexture(textureStream, true, TextureIO.PNG);
      //texture.setTexParameteri(GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR_MIPMAP_NEAREST);
      //texture.setTexParameteri(GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR_MIPMAP_NEAREST);
    }
    catch(Exception e) {
      println("Error loading texture: " + e);
    }
    
    return texture;
  }
  
  Texture loadTexture(String pImagePath) {
    Texture texture = null;
    
    try {
      texture = TextureIO.newTexture(new File(dataPath(pImagePath)), true);
    }
    catch(Exception e) {
      println("Error loading texture: " + e);
    }
      
    return texture;
  }
  
  void draw() {
    
    restFrame.setPosition(targetParticle.getPosition());
    Frame[] displayFrames = new Frame[] {restFrame, targetParticle};
    
    float PARTICLE_SIZE = prefs.getFloat("PARTICLE_SIZE");
    
    // GL SECTION BEGIN
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
    //targetParticle.drawHeadGL(gl);
    
    Vector3f intersection = new Vector3f();
    Vector3f[] intersections = new Vector3f[particles.size()*displayFrames.length];
    int intersectionCount = 0;
    
    for (int i=0; i < particles.size(); i++) {
      Particle p = (Particle)particles.get(i);
      
      // WORLDLINE PATH
      p.drawPathGL(gl);
      
      // AXES
      if ( !emissions.contains(p) ) {
        myAxes.drawGL(gl, (Frame)p);
      }
      
      // FIND SIMULT. PLANE INTERSECTIONS
      for (int j=0; j < displayFrames.length; j++) {
        
        intersection = p.getIntersection(displayFrames[j]);
        
        intersections[intersectionCount++] = intersection;
        
        p.drawHeadGL(gl, intersection);
      }
    }
    
    // PARTICLES (TEXTURE BILLBOARDS)
    particleTexture.enable(); //gl.glEnable(GL.GL_TEXTURE_2D); //gl.glEnable(particleTexture.getTarget());
    particleTexture.bind(); //gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]); //gl.glTexEnvf(GL.GL_TEXTURE_ENV, GL.GL_TEXTURE_ENV_MODE, GL.GL_MODULATE);
    
    Vector3f toParticle = new Vector3f();
    
    for (int i=0; i<intersectionCount; i++) {
      Particle p = (Particle)particles.get(i/2);
      
      float x = intersections[i].x;
      float y = intersections[i].y;
      float z = intersections[i].z;
      
      toParticle.set(intersections[i]);
      toParticle.sub(kamera.pos);
      
      float distToParticle = toParticle.length();
      float pulseFactor = 1.0 - 0.5*sin(p.properTime);
      
      float scale = distToParticle * 0.05* PARTICLE_SIZE * pulseFactor;
      
      // SCALEBOUNDS BEGIN
      //float s = min(distToParticle*0.1, 0.3);
      //s = max(s, distToParticle * 0.005);
      //float scale = s*10 *PARTICLE_SIZE * pulseFactor;
      
      color c = lerpColor(#FFFFFF, p.fillColor, 0.5*pulseFactor);
      
      //beginBillboardGL(kamera, x, y, z);
      beginCylindricalBillboardGL(x, y, z);
        
        gl.glColor4ub((byte)((c>>16) & 0xFF), (byte)((c>>8) & 0xFF), (byte)(c & 0xFF), (byte)((c>>24) & 0xFF));
        gl.glScalef(scale, scale, scale);
        simpleQuadGL(gl);
        
      endBillboardGL();
    }
    particleTexture.disable(); //particleTexture.dispose(); //gl.glDisable(GL.GL_TEXTURE_2D);
    
    // SELECTION (TEXTURE BILLBOARDS)
    selectedParticleTexture.bind();
    selectedParticleTexture.enable();
    
    for (int i=0; i<selection.size(); i++) {
      Particle p = (Particle) selection.get(i);
      Vector3f displayPos = p.getDisplayPositionVec();
      
      toParticle.sub(displayPos, kamera.pos);
      
      float distToParticle = toParticle.length();
      float scale = 0.25*distToParticle;
      
      gl.glColor4f(1, 1, 1, 0.35);
      beginCylindricalBillboardGL(displayPos.x, displayPos.y, displayPos.z);
        gl.glScalef(scale, scale, scale);
        simpleQuadGL(gl);
      endBillboardGL();
    }
    selectedParticleTexture.disable();
    
    // SELECTION LABELS
    for (int i=0; i<selection.size(); i++) {
      Particle p = (Particle) selection.get(i);
      Vector3f displayPos = p.getDisplayPositionVec();
      
      String label; 
      
      if (targets.contains(p)) {
        label = "Target: " + targets.indexOf(p);
      }
      else if (emissions.contains(p)) {
        label = "Emission: " + emissions.indexOf(p);
      }
      else {
        label = "Particle: " + i;
      }
      
      gl.glColor4f(1, 1, 1, 0.5);
      
      float labelScale = particleSelector.getHoverScale(p);
      myLabelor.drawLabelGL(gl, label, displayPos, labelScale); //fullScale);
    }
    
    // TARGETS (LINK INTERSECTIONS WITH HORIZONTAL PLANE)
    gl.glColor4f(0.4, 0.4, 0.4, 0.5);
    
    gl.glBegin(GL.GL_LINE_LOOP);
    for (int i=0; i < targets.size(); i++) {
      Particle p = (Particle) targets.get(i);
      Vector3f linkPos = p.getDisplayPositionVec();
      
      gl.glVertex3f(linkPos.x, linkPos.y, linkPos.z);
    }
    gl.glEnd();
    
    pgl.endGL();
  }
}

void simpleQuadGL(GL gl, float x, float y, float z) {
  gl.glPushMatrix();
  gl.glTranslatef(x, y, z);
  simpleQuadGL(gl);
  gl.glPopMatrix();
}

void simpleQuadGL(GL gl, float w, float h) {
  gl.glBegin(GL.GL_QUADS);
  gl.glTexCoord2f(w,h); gl.glVertex2f(w,h);
  gl.glTexCoord2f(w,0); gl.glVertex2f(w,-h);
  gl.glTexCoord2f(0,0); gl.glVertex2f(-w,-h);
  gl.glTexCoord2f(0,h); gl.glVertex2f(-w,h);
  gl.glEnd();
}

void simpleQuadGL(GL gl) {
  simpleQuadGL(gl, 1, 1);
  /*
  gl.glBegin(GL.GL_QUADS);
  gl.glTexCoord2f(1,1); gl.glVertex2f(1,1);
  gl.glTexCoord2f(1,0); gl.glVertex2f(1,-1);
  gl.glTexCoord2f(0,0); gl.glVertex2f(-1,-1);
  gl.glTexCoord2f(0,1); gl.glVertex2f(-1,1);
  gl.glEnd();
  */
}

void glTriangle(GL gl) {
  gl.glBegin(GL.GL_TRIANGLES);
  gl.glVertex2f(0, 1);
  gl.glVertex2f(-0.5, -1);
  gl.glVertex2f(+0.5, -1);
  gl.glEnd();
}

void beginBillboardGL(Kamera k, float x, float y, float z){
  gl.glPushMatrix();
  
  float dx = k.pos.x - x;
  float dy = k.pos.y - y;
  float dz = k.pos.z - z;
  float dxy = sqrt(dx*dx + dy*dy);
  float dxyz = sqrt(dz*dz + dxy*dxy);
  
  float theta_ct = degrees(atan2(dy, dx));
  float phi_ct = atan2(dz, dxy);
  
  gl.glTranslatef(x, y, z);
  
  //gl.glRotatef(degrees(frameCount)/10, 0f, 0f, 1f);
  
  gl.glRotatef(theta_ct, 0f, 0f, 1f);
  gl.glRotatef(degrees(-HALF_PI-phi_ct), 0f, 1f, 0f);
  gl.glRotatef(degrees(-HALF_PI), 0f, 0f, 1f);  
}

void endBillboardGL(){
  gl.glPopMatrix();
}

void beginCylindricalBillboardGL(float x, float y, float z){
  gl.glPushMatrix();
  
  gl.glTranslatef(x, y, z);
  
  float[] modelview = new float[16];
  
  gl.glGetFloatv(GL.GL_MODELVIEW_MATRIX, modelview, 0);
  
  for (int row=0; row<3; row++) {
    for (int col=0; col<3; col++) {
      modelview[row*4+col] = (row==col) ? 1 : 0;
    }
  }
  gl.glLoadMatrixf(modelview, 0);
}

//BILLBOARDING (in processing)
void drawBillboard(PImage img, float scale, Kamera kamera, float x, float y, float z){
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

  scale(scale);
  image(img, 0, 0);

  popMatrix();
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
      //float momentumNudge = 0.0001 ;
      float momentumNudge = prefs.getFloat("momentumNudge");
      
      float v_mag = particle.velocity.magnitude;
      
      float p = particle.mass * particle.velocity.gamma * v_mag;
      
      float vx = targetParticle.velocity.vx;
      float vy = targetParticle.velocity.vy;
      
      float heading_initial = particle.velocity.direction;
      
      float angleDiff = heading_initial - theta;
      
      // Help user slow down at high speeds, quickly but smoothly
      if ((v_mag > 0.99999) && abs(abs(angleDiff)-PI) < TWO_PI/5.0) {
        theta = heading_initial + PI + angleDiff * (1.0 - v_mag);
        momentumScale = 0.10;
        if (particle.impulseTotal > 0.1 * p) {
          println("particle.impulseTotal > 0.1 : " + particle.impulseTotal);
          momentumScale = 0.05;
        } 
      }
  
      float dp = amt * (momentumScale * p + momentumNudge);
  
      float dp_x = dp * cos(theta);
      float dp_y = dp * sin(theta);
      
      if (prefs.getBoolean("1-D_control")) {
        dp_y = 0;
      }
      
      particle.propelSelf(dp_x, dp_y);
  }
}

void mousePressed() {
  
  if (mouseButton == RIGHT) {
    MOUSELOOK = !MOUSELOOK;
    
    if (MOUSELOOK) {
      cursor(MOVE);
    } else {
      cursor(ARROW);//noCursor();
    }
  }
  else if (mouseButton == LEFT) {
    
    Particle particle = particleSelector.pickPoint(kamera, mouseX, mouseY);
    //Particle particle = particleSelector.pickPoint(kamera.pos, direction);
    if (particle != null) {
      particleSelector.invertSelectionStatus(particle);
    }
    else {
      particleSelector.clear();
    }
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
    int i = (int) random(prefs.getInteger("PARTICLES"));
    targetParticle = (Particle) particles.get(i);
    targetParticle.setFillColor(color(#F01B5E));
    targets.add(particles.get(i));
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
}

