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

int n_particles = 200;

float zoomVelocity = 0;

String FONT = "BitstreamVeraSansMono-Roman-48.vlw";

Infobox myInfobox;
//Infoline fpsLine;

void setup() {

  size(1200, 800, OPENGL);

  myInfobox = new Infobox(FONT, 32);

  origin = new Particle(new PVector(0,0,0), new PVector(0,0,0));
  origin.fillColor = color(#48F01B);//#F01B5E);//
  
  particles = new Particle[n_particles];

  for(int i=0; i<n_particles; i++){
    PVector pos = new PVector(random(-100, 100), random(-100, 100), 0);
    PVector vel = new PVector(random(-1,1), random(-1,1));
    vel.normalize();

    particles[i] = new Particle(pos, vel);
    particles[i].fillColor = color(#1B83F0);
  }
  
  targetParticle = origin;
  
  kamera = new Kamera();
  kamera.target = targetParticle.pos.get();

  //strokeWeight(1);
}

void draw(){
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
//  gl.glDisable(GL.GL_DEPTH_TEST);
//  gl.glDepthMask(false);
  
  pgl.endGL();
  
  lights();
  background(15, 15, 15);
  
  directionalLight(3, 115, 140, // Color 
    10, 10, -1); // The x-, y-, z-axis direction' 
  directionalLight(2, 83, 115, // Color 
    1, 10, -1); // The x-, y-, z-axis direction' 

  kamera.target = targetParticle.pos.get();
  kamera.update(timeDelta);
//  pointLight(220, 220, 220, kamera.pos[0], kamera.pos[1], kamera.pos[2]);

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
  + "CameraZ: " + nf(kamera.pos.x, 3, 2)
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
    
    pos = new PVector();
    updatePosition();
    
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
  
  void updatePosition() {
    pos.x = target.x + radius * sin(zenith) * cos(azimuth);
    pos.y = target.y + radius * sin(zenith) * sin(azimuth);
    pos.z = target.z + radius * cos(zenith);
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
    
    updatePosition();
    
    camera(pos.x, pos.y, pos.z,
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
  
  PVector pos;
  PVector target;
}
