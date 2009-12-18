// Worldlines
// tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;
import javax.vecmath.*;
import geometry.*;

import com.sun.opengl.util.texture.*;
import com.sun.opengl.util.BufferUtil;
import java.nio.ByteBuffer;
import java.nio.Buffer;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

//Particle[] particles;
ArrayList particles;
Particle targetParticle;
ArrayList targets;
ArrayList emissions;

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
  size(900, 540, OPENGL);
  //size(1280, 900, OPENGL);
  
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
  
  particles = new ArrayList(); //particles = new Particle[MAX_PARTICLES];
  particles.add(targetParticle); //particles[0] = targetParticle;  

  for(int i=1; i<PARTICLES; i++){

    float x = pow(10, START_POS_DISPERSION_X);
    float y = pow(10, START_POS_DISPERSION_Y);
    
    Vector3f pos = new Vector3f(random(-x, +x), random(-y, +y), 0);
    
    // Exponentially weight distribution of velocities towards lightspeed
    float vel_mag = 1-pow(random(1, 2), -START_VEL_DISPERSION);
    float heading = random(TWO_PI);
    
    float vx = vel_mag*cos(heading);
    float vy = vel_mag*sin(heading)*(pow(1.5, -START_VEL_ECCENTRICITY));
    
    Vector3f vel = new Vector3f(vx, vy, 0);
    
    Particle p = new Particle(pos, vel);
    p.setFillColor(color(#1B83F0));
    particles.add(p); //particles[i] = p;
  }
  
  println("target pos: " + targetParticle.position.x + ", " + targetParticle.position.y );
  println("target direction: " + targetParticle.velocity.direction);
  println("target magnitude: " + targetParticle.velocity.magnitude);
  println("target gamma:     " + targetParticle.velocity.gamma);
  
  targets = new ArrayList();
  for (int i=0; i<TARGETS; i++) {
    addTarget((Particle)particles.get(i));
  }
  
  emissions = new ArrayList();
  
  kamera = new Kamera();
    
  restFrame = new DefaultFrame();
  restFrame.setVelocity(0,0);
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
    particlesLayer = new ParticlesLayer(particles, PARTICLE_IMAGE, kamera);
  pgl.endGL();
  
  inputDispatch = new InputDispatch(targets);
  
  particleGrid = new ParticleGrid(3*50, 5*1000);
  targetAxes = new Axes((Frame)targetParticle);
  
  Velocity restFrameVel = new Velocity(0, 0);
  
  // THREADING
  particleUpdater = new ParticleUpdater(targetParticle, particles);
  //Relativity.loadFrame(targetParticle);
  //particleUpdater.start();

  frameRate(30);
  //hint(DISABLE_DEPTH_SORT);
}

void addTarget(Particle p){
  targets.add(p);
  p.velocity.set(targetParticle.velocity);
  p.setFillColor(TARGET_COLOR);
}

void addEmission(Particle e){
  emissions.add(e);
  particles.add(e);
  e.setFillColor(color(0, 1, 0));
}

float[] vel = new float[3];

void draw() {
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glScalef(1,1,1);
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  gl.glLineWidth(STROKE_WIDTH);
  pgl.endGL();
  
  // SCENE PREP
  background(30);
  //colorMode(HSB, 255);
  //background((frameCount * 0.5)%255, 100, 75, 255);//  background(#3473F7);
  //background((frameCount * 0.5)%255, 200, 24, 255);//  background(#3473F7);
  //colorMode(RGB, 1.0f);
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
      Particle p = (Particle)particles.get(i);//Particle p = particles[i];
      p.update(dt);
      p.updateTransformedHist();
    }
    
    for (int i=0; i<emissions.size(); i++) {
      Particle e = (Particle) emissions.get(i);
      e.update(dt);
      e.updateTransformedHist();
    }
  }
  else {
    // UPDATE TARGET  
    targetParticle.update(dt);  
    targetParticle.updateTransformedHist();
    
    // UPDATE NON-TARGETS
    for (int i=0; i<PARTICLES; i++) {
      Particle p = (Particle)particles.get(i);
      
      if (p == targetParticle)
      {
        continue;
      }
      else if( p.xyt_prime[2] > targetParticle.xyt_prime[2] )
      {
        p.updateTransformedHist();
        continue;
      } 
      else {
        p.update(dt);
        p.updateTransformedHist();
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
  ArrayList particles; //Particle[] particles;
  PImage particleImage;
  Kamera kamera;
  
  boolean useGL = true;
  
  Texture particleTexture;
  int[] textures = new int[3];
    
  ParticlesLayer (ArrayList particles, String particleImagePath, Kamera kamera) {
    this.particles = particles;
    this.kamera = kamera;
    this.particleImage = loadImage(particleImagePath);
    this.particleTexture = loadTexture(particleImagePath);
    //this.particleTexture = loadTextureFromStream(openStream(particleImagePath));
    //loadTextureGL(openStream(particleImagePath));
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
    //ByteBuffer textureByteBuffer = BufferUtil.newByteBuffer(imgWidth*imgHeight*bytesPerPixel);
    
    //ByteBuffer textureByteBuffer = textureData.getBuffer();
    
    //byte[] textureBytes = new byte[32];
    //textureByteBuffer.get(textureBytes);
    //dumpBytes(textureBytes, 32);
    
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
      //textureByteBuffer
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
    
    //dumpStreamBytes(textureStream, 32);
    try {
      //textureData = TextureIO.newTextureData(textureStream, true, TextureIO.PNG);
      texture = TextureIO.newTexture(textureStream, false, TextureIO.PNG);
      texture.setTexParameteri(GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
      texture.setTexParameteri(GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
    }
    catch(Exception e) {
      println("Error loading texture: " + e);
    }
    
    return texture;
    /*
    if (textureData != null) {
      texture = TextureIO.newTexture(textureData);
      println("textureData.toString(): " + textureData.toString());
    }
    else {
      println("textureData was null");
    }
    */
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
        
    // GL SECTION BEGIN
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
    //targetParticle.drawHeadGL(gl);
    
    Vector3f intersection = new Vector3f();
    Vector3f[] intersections = new Vector3f[MAX_PARTICLES*displayFrames.length];
    int intersectionCount = 0;
    
    for (int i=0; i < particles.size(); i++) {
      Particle p = (Particle)particles.get(i);
      
      p.drawPathGL(gl);
      targetAxes.drawGL(gl, (Frame)p);
      
      for (int j=0; j < displayFrames.length; j++) {
        
        intersection = p.getIntersection(displayFrames[j]);
        
        intersections[intersectionCount++] = intersection;
        
        p.drawHeadGL(gl, intersection);
        
        //p.drawIntersectionGL(gl, displayFrames[j]);
        //p.drawIntersectionGL(gl, (Frame)targetParticle);
        //p.drawIntersectionGL(gl, (Frame)restFrame);
      }
    }
    pgl.endGL();
    
    if (useGL) {
      
      pgl.beginGL();
      
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
        color c = lerpColor(#FFFFFF, p.fillColor, 0.5*pulseFactor);
        
        //beginBillboardGL(kamera, x, y, z);
        beginCylindricalBillboardGL(kamera, x, y, z);
          
          gl.glColor4ub((byte)((c>>16) & 0xFF), (byte)((c>>8) & 0xFF), (byte)(c & 0xFF), (byte)((c>>24) & 0xFF));
          gl.glScalef(scale, scale, scale);
          simpleQuad(gl);
          
        endBillboardGL();
      }
      particleTexture.disable(); //particleTexture.dispose(); //gl.glDisable(GL.GL_TEXTURE_2D);
      
      pgl.endGL();
      
    }
    else {
    
      // PROCESSING SECTION
      imageMode(CENTER);
      
      Vector3f toParticle = new Vector3f();
      float distToParticle;
      
      for (int i=0; i<intersectionCount; i++) {
        Particle p = (Particle)particles.get(i/2);
        
        float[] pos = new float[3];
        intersections[i].get(pos);
        
        toParticle.set(intersections[i]);
        toParticle.sub(kamera.pos);
        
        distToParticle = toParticle.length();
        
        float pulseFactor = 1 - 0.5*sin(p.properTime);
        //float dim = LIGHTING_PARTICLES * constrain(distToParticle * 0.005, 0, 1);
        
        //scale *= PARTICLE_SIZE * 0.1 * pulseFactor*0.0015*log(distToParticle);
        float scale = PARTICLE_SIZE * 0.1 * pulseFactor*0.0015*distToParticle;
        
        tint(lerpColor(#FFFFFF, p.fillColor, 0.5*pulseFactor), pulseFactor);
        
        p.drawHead(pos[0], pos[1], pos[2]);
        drawBillboard(particleImage, scale, kamera, pos[0], pos[1], pos[2]);
        
        noTint();
      }
    }
  }
  
  void simpleQuad(GL gl) {
    gl.glBegin(GL.GL_QUADS);
    gl.glTexCoord2f(1,1); gl.glVertex2f(1,1);
    gl.glTexCoord2f(1,0); gl.glVertex2f(1,-1);
    gl.glTexCoord2f(0,0); gl.glVertex2f(-1,-1);
    gl.glTexCoord2f(0,1); gl.glVertex2f(-1,1);
    gl.glEnd();
  }
}

void dumpStreamBytes(InputStream inputStream, int numBytes) {
  try {
    byte[] b = new byte[numBytes];
    inputStream.read(b, 0, numBytes);
    
    println("inputStream.toString(): " + inputStream.toString());
    println("inputStream Bytes[0.."+numBytes+"]:");
    
    dumpBytes(b, numBytes);
    
  }
  catch (Exception e){
    println("Error reading inputStream: ");
  }
}

void dumpBytes(byte[] b, int numBytes){
  
  for (int i=0; i<numBytes/8; i++){
    for (int j=0; j<8; j++){
      print(" " + b[i*8+j]);
    }
    println("\t");
  }
}
/*
void glTriangle(GL gl) {
        gl.glBegin(GL.GL_TRIANGLES);
        gl.glVertex2f(0, 1);
        gl.glVertex2f(-0.5, -1);
        gl.glVertex2f(+0.5, -1);
        gl.glEnd();
}
*/

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

void beginCylindricalBillboardGL(Kamera k, float x, float y, float z){
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
      
      //particle.addImpulse(dp_x, dp_y);
      particle.propelSelf(dp_x, dp_y);
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
    targetParticle = (Particle) particles.get(i);
    targetParticle.setFillColor(color(#F01B5E));
    targets.add(particles.get(i));
  }
  
  if (key == 'g' || key == 'G') {
    particlesLayer.useGL = !particlesLayer.useGL;
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

static class Dbg {
  static void dumphex(String name, int i) {
    println("hex(" + name + "): " + hex(i));
  }
}

