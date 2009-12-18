public class Velocity {
  float vx,  vy;
  float direction;
  float magnitude;
  float gamma;
  
  Vector3f[] basis = new Vector3f[] {
    new Vector3f(15, 0, 0),
    new Vector3f(0, 15, 0),
    new Vector3f(0, 0, 15)
  };
  
  // Orthonormal basis after lorentz inverse transform; ie, in frame measuring our vel
  Vector3f[] basis_inverse = new Vector3f[] {
    new Vector3f(), new Vector3f(), new Vector3f()
  };
  
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
    
    for (int i=0; i<3; i++) {
      basis_inverse[i] = new Vector3f();
    }
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
      basis_inverse[i].set(Relativity.inverseTransform(this, basis[i]));
    }
    
    // n = basis_x cross basis_y :
    normal.cross(basis_inverse[0], basis_inverse[1]);
  }
}

