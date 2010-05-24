// Geom
// tflorez

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
  
  public Line(Vector3f point, Vector3f direction) {
    p.set(point);
    d.set(direction);
  }
  
  public void defineBySegment(Vector3f va, Vector3f vb) {
    p.set(va);
    setDirection(
      vb.x - va.x,
      vb.y - va.y,
      vb.z - va.z );
  }
  
  public void setPoint(float x, float y, float z) {
    p.set(x, y, z);
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
  
  public void setPoint(Vector3f point){
    p.set(point);
    updateABCD();
  }

   public void setPoint(float[] point){
    p.set(point);
    updateABCD();
  }
  
  public void setPoint(float x, float y, float z) {
    p.set(x, y, z);
    updateABCD();
  }
  
  public void setNormal(Vector3f normal){
    n.set(normal);
    updateABCD();
  }
  
  public void setNormal(float x, float y, float z) {
    n.set(x, y, z);
    updateABCD();
  }
  
  public void updateABCD() {
    A = n.x;
    B = n.y;
    C = n.z;
    D = -(A * p.x + B * p.y + C * p.z);
  }
  
  public boolean liesBelow(Vector3f thePoint) {
    
    Vector3f toThePoint = new Vector3f();
    toThePoint.sub(thePoint, this.p);
    
    return (this.normal.dot(toThePoint) > 0);
  }
  
  /* Distance along line direction l.d to intersection:
   * t = -(A px + B py + C pz + D) / (A dx + B dy + C dz)
   * 
   * Alternative:
   * t = -(n.dot(l.p) + D) / n.dot(l.d);
   */
  public void getIntersection(Line l, Vector3f target) {
    
    float t = -(A*l.p.x + B*l.p.y + C*l.p.z + D) / (A*l.d.x + B*l.d.y + C*l.d.z);

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

