// tflorez

public class Velocity {
  float vx,  vy;
  float direction;
  float magnitude;
  float gamma;
  
  Vector3f[] basis = new Vector3f[] {
    new Vector3f(1, 0, 0),
    new Vector3f(0, 1, 0),
    new Vector3f(0, 0, 1)
  };
  
  Vector3f[] displayBasis = new Vector3f[] {
    new Vector3f(),
    new Vector3f(),
    new Vector3f()
  };
  
  // Orthonormal basis after lorentz inverse transform; ie, in frame measuring our vel
  Vector3f[] basisInverse = new Vector3f[] {
    new Vector3f(), new Vector3f(), new Vector3f()
  };
  
  Vector3f threeVelocity = new Vector3f();
  
  // Normal vector to plane of simultaneity in rest frame coords; ie, basis: x cross y
  Vector3f normal = new Vector3f();
  
  Velocity (float vx, float vy) {
    setComponents(vx, vy);
  }
  
  Velocity () {
    this(0f, 0f);
  }
  
  void set(Velocity sourceVel) {
    setComponents(sourceVel.vx, sourceVel.vy);
  }
  
  void setComponents(float vx, float vy) {
    this.vx = vx;
    this.vy = vy;
    
    direction = atan2(vy, vx);
    magnitude = (float)Math.sqrt(vx*vx + vy*vy);
    updateGamma();
    updateBasis();
  }
  
  void setDirection(float direction) {

    this.direction = direction;
    updateComponents();
  }
  
  void setMagnitude(float magnitude) {

    this.magnitude = magnitude;
    updateGamma();
    updateComponents();
  }
  
  void updateComponents() {
    vx = magnitude * cos(direction);
    vy = magnitude * sin(direction);
    updateBasis();
  }
  
  void updateGamma() {
    gamma = Relativity.gamma(magnitude);
  }
  
  void updateBasis() {
    
    for (int i=0; i<3; i++) {
      basisInverse[i] = Relativity.inverseLorentzTransform(this, basis[i]);
    }

    threeVelocity.set(basisInverse[2]);
    normal.cross(basisInverse[0], basisInverse[1]);
  }
  
  Vector3f getThreeVelocity() {
    return threeVelocity;
  }
  
  String toString() {
    return super.toString() + " vx: " + vx + ", vy: " + vy;
  }
}

