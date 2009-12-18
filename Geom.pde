/*
package Geometry;

import javax.vecmath.*;

public class Line {
  Vector3f p = new Vector3f();
  Vector3f d = new Vector3f();
  
  public Line() {
    p.set(0,0,0);
    d.set(1,1,1);
  }
  
  public Line(float[] point, float[] direction) {
    p.set(point);
    d.set(direction);
  }
  
  public void setPoint(float[] point){
    p.set(point);
  }
  
  public void setDirection(float dx, float dy, float dz){
    d.set(dx, dy, dz);
  }
  
  public String toString() {
    return new String( 
      "line { \n" + 
      "point:     " + p.toString() + "\n" +
      "direction: " + d.toString() + "\n" +
      "}\n");
  }
}

public class Plane {
  // an arbitrary point on the plane
  Vector3f p = new Vector3f();
  Vector3f point = p;
  
  // normal vector to the plane
  Vector3f n = new Vector3f();
  Vector3f normal = n;
  
  // Parameters in plane equation: Ax + By + Cz + D = 0
  float A, B, C, D;
  
  public Plane(){
    p.set(0,0,0);
    n.set(1,1,1);
  }
  
  public Plane(float[] point, float[] normal){
    
    p = new Vector3f(point);
    n = new Vector3f(normal);
    
    updateABCD();
  }
  
  public void setPoint(float[] point){
    p.set(point);
    updateABCD();
  }
  
  public void setNormal(Vector3f normal){
    n.set(normal);
    updateABCD();
  }
  
  public void updateABCD() {
    A = n.x;
    B = n.y;
    C = n.z;
    D = -(A * p.x + B * p.y + C * p.z);
  }
  
  public void getIntersection(Line l, Vector3f target) {
    // t = -(A px + B py + C pz + D) / (A dx + B dy + C dz)
    // t = (n.dot(l.p) + D) / n.dot(l.d);
    
    float t = -(A*l.p.x + B*l.p.y + C*l.p.z + D) / (A*l.d.x + B*l.d.y + C*l.d.z);
    //float t = -(n.dot(l.p) + D) / n.dot(l.d);
    
    // target = lp + t * ld
    target.scaleAdd(t, l.d, l.p);
  }
  
  public String toString() {
    return new String( "plane { \n" + 
      "point:  " + p.toString() + "\n" +
      "normal: " + n.toString() + "\n" +
      "}\n"
    );
  }
}
*/
