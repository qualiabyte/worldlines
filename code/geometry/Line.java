package geometry;

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

  public void setPoint(Vector3f v){
		p.set(v);
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

