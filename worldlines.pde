//Worldlines
//tflorez

import processing.opengl.*;
import javax.media.opengl.GL;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Particle origin;
Particle[] particles;

Particle targetParticle;
PVector target;
PVector prevTarget;

//float time = 0;
float timeDelta = 0.1;

int n_particles = 500;

float zoomVelocity = 0;

String FONT = "BitstreamVeraSansMono-Roman-48.vlw";

Infobox myInfobox;
//Infoline fpsLine;

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
  
  targetParticle = origin;
  
  kamera = new Kamera();
  kamera.target = targetParticle.pos.get();

}

void draw(){
  //  pgl = (PGraphicsOpenGL)g;
  //  gl = pgl.beginGL();
  lights();
  background(15, 15, 15);

  kamera.target = targetParticle.pos.get();
  kamera.update(timeDelta);

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
  
  myInfobox.print( 
  (int) frameRate + " fps\n"
  + (int) millis() / 1000 + " seconds\n"
  + "CameraZ: " + nf(kamera.position()[2], 3, 2)
  );
}
/*
PVector PVector(float[] v){
  return new PVector(v[0], v[1], v[2]);  
}
*/
class Kamera {
  
  Kamera() {
    radius = 100;
    azimuth = PI;
    zenith = PI/6;
    target = new PVector(0,0,0);
    
    radiusVel = azimuthVel = zenithVel = 0;
    velDecay = 0.9;
    
    mouseWheel = 0;
    
    perspective(PI/3.0, width/height, 1, 15000);
    
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
  
  float[] position() {
    float x = target.x + radius * sin(zenith) * cos(azimuth);
    float y = target.y + radius * sin(zenith) * sin(azimuth);
    float z = target.z + radius * cos(zenith);
    
    return new float[] {x, y, z};
  }
  
  void update(float dt) {
    if (mousePressed && mouseButton == RIGHT){
      zenithVel -= (float)(mouseY - pmouseY)/10;
      azimuthVel += (float)(mouseX - pmouseX)/10;
    }
    
    radiusVel += mouseWheel;
    mouseWheel *= 0.1;
    
    radius = abs(radius - radius * radiusVel / 60);
    radiusVel *= velDecay;
    
    azimuth = (azimuth + azimuthVel / 60) % (TWO_PI);
    azimuthVel *= velDecay;
    
    zenith = constrain(zenith + zenithVel / 60, EPSILON, PI - EPSILON);
    zenithVel *= velDecay;
    
    float[] eye = position();
    
    camera(eye[0], eye[1], eye[2],
    target.x, target.y, target.z,
    0, 0, -1
    );
  }
  
  float mouseWheel;
  
  float velDecay;
  
  float radiusVel;
  float azimuthVel;
  float zenithVel;
  
  float radius;
  float azimuth;
  float zenith;
  PVector target;
}
