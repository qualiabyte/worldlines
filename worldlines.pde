//Worldlines
//tflorez

import processing.opengl.*;
import javax.media.opengl.GL;

import damkjer.ocd.*;

PGraphicsOpenGL pgl;
GL gl;

Camera camera1;
float camZenithVelocity = 0;
float camAzimuthVelocity = 0;

Particle origin;
Particle[] particles;

Particle targetParticle;
PVector target;
PVector prevTarget;

float time = 0;
float timeDelta = 0.1;

int n_particles = 100;

float mouseWheel = 0;
float zoomVelocity = 0;

String FONT = "BitstreamVeraSansMono-Roman-48.vlw";

Infobox myInfobox;
Infoline fpsLine;

void setup() {

  size(1200, 800, OPENGL);

  myInfobox = new Infobox(FONT, 32);

  origin = new Particle(new PVector(0,0,0), new PVector(0,0,0));
  particles = new Particle[n_particles];

  for(int i=0; i<n_particles; i++){
    PVector pos = new PVector(random(-100, 100), random(-100, 100), 0);
    PVector vel = new PVector(random(-1,1), random(-1,1));
    vel.normalize();

    particles[i] = new Particle(pos, vel);
  }
  
  camera1 = new Camera(this, 0, 100, 15, //position
  0,0,0, // target
  0,0,-1 // up-direction
  );
  //camera1.roll(PI);
  //camera1.tilt(PI/2);
  
  targetParticle = origin;
  target = targetParticle.pos;
  prevTarget = target.get();

  camera1.aim(target.x, target.y, target.z);

  addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
    }
  }
  ); 
}

void mouseWheel(int delta) {
  mouseWheel += delta;
  println(mouseWheel);
}

void draw(){
  //  pgl = (PGraphicsOpenGL)g;
  //  gl = pgl.beginGL();
  lights();
  background(15, 15, 15);

//  camera();
//  perspective();
  
  /*
  // Change height of the camera with mouseY
   camera(0, 0, mouseY, // eyeX, eyeY, eyeZ
   0.0, 0.0, 0.0, // centerX, centerY, centerZ
   0.0, 1.0, 0.0); // upX, upY, upZ
   */

  PVector camPos = PVector(camera1.position());
  
  prevTarget = target.get();
  target = targetParticle.pos.get();
  
  PVector targetDelta = PVector.sub(target, prevTarget);
  
  //float[] prevTarget = camera1.target();
  
  float targetDeltaX = target.x - prevTarget.x;
  float targetDeltaY = target.y - prevTarget.y;
  float targetDeltaZ = target.z - prevTarget.z;
  
  camera1.jump(camPos.x + targetDeltaX, camPos.y + targetDeltaY, camPos.z + targetDeltaZ);
  camera1.aim(target.x, target.y, target.z);
  
//  PVector axisPos = PVector.mult(PVector.sub(target, camPos), 0.9);

  if (mousePressed && mouseButton == RIGHT){
    camZenithVelocity -= (float)(mouseY - pmouseY)/10;
    camAzimuthVelocity += (float)(mouseX - pmouseX)/10;
  }
//  camera1.arc(camZenithVelocity/300);
  camZenithVelocity *= 0.9;
  
//  camera1.circle(camAzimuthVelocity/300);
  camera1.tumble(camAzimuthVelocity/300, camZenithVelocity/300);
  camAzimuthVelocity *= 0.9;
  
  if (abs(zoomVelocity) > 0.01 || mouseWheel != 0){
    zoomVelocity += mouseWheel;
    
    camPos = PVector(camera1.position());
    
    camera1.dolly(zoomVelocity / 30 * target.dist(camPos)); //new PVector(camPos[0], camPos[1], camPos[2])));
    zoomVelocity *= 0.9;
    mouseWheel *= 0.5;
  }
  
  camera1.feed();

  fill(0,0,200);
  stroke(0,200,200);

  for (int i=0; i<n_particles; i++){
    particles[i].drawHead();
    particles[i].drawPath();
    particles[i].update(timeDelta);
  }
  
  fill(200,0,0);
  origin.draw();
  origin.update(timeDelta);

  float[] up = camera1.up();
  
  myInfobox.print( 
  (int) frameRate + " fps\n"
  + (int) millis() / 1000 + " seconds\n"
  + "Cam1.up(): " + join(" ", new String[] {nf(up[0], 3, 2), nf(up[1], 3, 2), nf(up[2], 3, 2)})
  + "\nCameraZ: " + nf(camera1.position()[2], 3, 2)
  );
}

PVector PVector(float[] v){
  return new PVector(v[0], v[1], v[2]);  
}

class Kamera {
  
  Kamera() {
    radius = 100;
    azimuth = PI/2;
    zenith = -PI;
    target = new PVector {0,0,0};
    
    radiusVel = azimuthVel = zenithVel = 0;
    velDecay = 0.9;
  }
  
  float[] position() {
    float x = target.x + radius * Sin(zenith) * Cos(azimuth);
    float y = target.y + radius * Sin(zenith) * Sin(azimuth);
    float z = target.z + radius * Cos(zenith);
    
    return new float[] {x, y, z};
  }
  
  void update(float dt) {
    radius = abs(radius - radius * radiusVel / 30);
    radiusVel *= velDecay;
    
    azimuth = (azimuth + azimuthVel) % (TWO_PI);
    azimuthVel *= velDecay;
    
    zenith = constrain(zenith + zenithVel, 0, PI);
    zenithVel *= velDecay;
  }
  
  float velDecay;
  
  float radiusVel;
  float azimuthVel;
  float zentihVel;
  
  float radius;
  float azimuth;
  float zenith;
  PVector target;
}

/*
class OCD extends Camera {
  OCD (PApplet aParent) {
    super(aParent);
  }
  
  void setUp(float x, float y, float z) {
    theUpX = x;
    theUpY = y;
    theUpZ = z;
  }

}

*/
