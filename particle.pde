class Particle{

  Particle( PVector pos, PVector vel ){
    this.pos = pos;
    this.vel = vel;
    
    path = new float[pathCountMax][3];
    updatePath();
  }
  
  void update(float dt){
    pos.add(PVector.mult(vel, dt));
    pos.z += dt;
    properTime += dt * Relativity.gamma(vel);
  }
  
  void updatePath(){
    path[pathCount++] = pos.array();
  }
  
  void draw(){
    drawHead();
  }
  
  void drawHead(){
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    
    PVector vel2D = new PVector(vel.x, vel.y);
    
    float heading = vel2D.heading2D();
    //println(heading);
    rotate(heading);
    triangle(0, 1, -.5, -1, .5, -1);
    //box(5, 5, 1);
    popMatrix();
  }
  
  void drawPath(){
    float[] from, to;
    
    for(int i=0; i<pathCount-1; i++){
      from = path[i];
      to = path[i+1];
      line(from[0], to[0], from[1], to[1], from[2], to[2]);
    }
  }
  
  int pathCountMax = 1000;
  
  float[][] path;
  int pathCount=0;
  
  PVector pos;
  PVector vel;
  
  color colorValue = color(255);
  float properTime=0;
}
