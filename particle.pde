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
    
    if (frameCount % 120 == 1) {
      updatePath();
    }
    
  }
  
  void updatePath(){
    path[pathCount++] = pos.get().array();
  }
  
  void draw(){
    drawHead();
    drawPath();
  }
  
  void drawHead(){
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    
    PVector vel2D = new PVector(vel.x, vel.y);
    
    float heading = vel2D.heading2D();

    rotate(heading - PI/2);
    
    fill(fillColor);
//    noStroke();
//    ambient(100);
//    shininess(3.0);
//    specular(50, 0, 100);
    triangle(0, 1, -.5, -1, .5, -1);
    //box(5, 5, 1);
    popMatrix();
  }
  
  void drawPath(){
    float[] from, to;
    
    int alpha = abs((3*frameCount + (this.hashCode() >> 19)) % 510 - 255);
//    beginShape();
    for(int i=0; i<pathCount-1; i++){
      from = path[i];
      to = path[i+1];
      stroke(pathColor, 255*i/pathCount - alpha);
//      vertex(path[i+1][0], path[i+1][1], path[i+1][2]);
/*    
      pushMatrix();
      translate(from[0], from[1], from[2]);
      triangle(0,-1,-0.5,0,0.5,0);
      popMatrix();
*/

      line(from[0], from[1], from[2], to[0], to[1], to[2]);
    }
//    vertex(pos.x,pos.y,pos.z);
//    endShape();
    line( path[pathCount-1][0], path[pathCount-1][1], path[pathCount-1][2],
    pos.x, pos.y, pos.z );
  }
  
  int pathCountMax = 1000;
  
  float[][] path;
  int pathCount=0;
  
  PVector pos;
  PVector vel;
  
  color fillColor;
  color pathColor = color(0,200,200);
  float properTime=0;
}
