// Relativity
// tflorez

static class Relativity {
  
  static Velocity v;
  
  // TRANSFORM MODE
  public static boolean TOGGLE_SPATIAL_TRANSFORM;
  public static boolean TOGGLE_TEMPORAL_TRANSFORM;
  
  static float C = 1.0f;
  
  public static float gamma(float v) {
    return //( abs(v-1) < 1E-9) ? 99E31 :
           1.0f / (float) Math.sqrt(1 - v*v);
  }
  
  public static void loadVelocity(Velocity velocity) {
    v = velocity;
  }

  public static void loadFrame(Frame f) {
    loadVelocity(f.getVelocity());
  }
  
  
  public static Matrix3f getLorentzMatrix() {
    
    return new Matrix3f(
      v.gamma,              0,    -v.magnitude*v.gamma, // X
      0,                    1,    0,                    // Y
      -v.magnitude*v.gamma, 0,    v.gamma               // T
    );    
  }
  
  public static Matrix3f getLorentzInverseMatrix() {
    
    return new Matrix3f(
      v.gamma,             0,    v.magnitude*v.gamma, // X
      0,                   1,    0,                   // Y
      v.magnitude*v.gamma, 0,    v.gamma              // T
    );
  }
  
  public static Matrix3f getRotationMatrix(float a, float x, float y, float z) {
    
    float c = cos(a);
    float s = sin(a);
    
    Matrix3f M = new Matrix3f(
    x*x*(1-c)+c,    x*y*(1-c)-z*s,    x*z*(1-c)+y*s,
    y*x*(1-c)+z*s,  y*y*(1-c)+c,      y*z*(1-c)-x*s,
    x*z*(1-c)-y*s,  y*z*(1-c)+x*s,    z*z*(1-c)+c 
    );
    
    return M;
  }
  
  public static Matrix3f getInverseLorentzTransformMatrix(Velocity vel) {
    loadVelocity(vel);
    
    Matrix3f rotHeadingInverse = getRotationMatrix(-v.direction, 0, 0, 1);
    Matrix3f inverseLorentz = getLorentzInverseMatrix();
    Matrix3f rotHeading = getRotationMatrix(v.direction, 0, 0, 1);
    
    Matrix3f M = new Matrix3f();
    M.set(rotHeading);
    M.mul(inverseLorentz);
    M.mul(rotHeadingInverse);
    
    return M;
  }
  
  public static Matrix3f getLorentzTransformMatrix(Velocity vel) {
    loadVelocity(vel);
    
    Matrix3f rotHeadingInverse = getRotationMatrix(-v.direction, 0, 0, 1);
    Matrix3f lorentz = getLorentzMatrix();
    Matrix3f rotHeading = getRotationMatrix(v.direction, 0, 0, 1);
    
    Matrix3f M = new Matrix3f();
    M.set(rotHeading);
    M.mul(lorentz);
    M.mul(rotHeadingInverse);
    
    return M;
  }
  
  public static Vector3f inverseTransform(Velocity vel, Vector3f v) {
    
    Vector3f v_prime = new Vector3f();
    
    Matrix3f M = getInverseLorentzTransformMatrix(vel);    
    
    M.transform(v, v_prime);
    
    return v_prime;
  }
  
  public static Vector3f inverseDisplayTransform(Velocity vel, Vector3f v_display) {
    
    Vector3f v_inverse = inverseTransform(vel, v_display);
    
    v_inverse.set(
      TOGGLE_SPATIAL_TRANSFORM ? v_inverse.x : v_display.x,
      TOGGLE_SPATIAL_TRANSFORM ? v_inverse.y : v_display.y,
      TOGGLE_TEMPORAL_TRANSFORM ? v_inverse.z : v_display.z
    );
    return v_inverse;
  }
  
  public static void selectInverseDisplayComponents(Vector3f v_inverse, Vector3f v_display, Vector3f target) {
  
    target.set(
      TOGGLE_SPATIAL_TRANSFORM ? v_inverse.x : v_display.x,
      TOGGLE_SPATIAL_TRANSFORM ? v_inverse.y : v_display.y,
      TOGGLE_TEMPORAL_TRANSFORM ? v_inverse.z : v_display.z
    );
  }
  
  public static void lorentzTransform(Velocity vel, Vector3f source, Vector3f target){
    
    Matrix3f M = getLorentzTransformMatrix(vel);
    
    M.transform(source, target);
  }
  
  public static Vector3f displayTransform(Velocity vel, Vector3f v) {
    Vector3f v_prime = new Vector3f();
    
    lorentzTransform(vel, v, v_prime);
    selectDisplayComponents(v, v_prime, v_prime);
    
    return v_prime;
  }

  public static void displayTransform(Matrix3f theLorentzMatrix, Vector3f source, Vector3f target) {
    float sx = source.x;
    float sy = source.y;
    float sz = source.z;
    
    theLorentzMatrix.transform(source, target);

    target.set(
      TOGGLE_SPATIAL_TRANSFORM ? target.x : sx,
      TOGGLE_SPATIAL_TRANSFORM ? target.y : sy,
      TOGGLE_TEMPORAL_TRANSFORM ? target.z : sz );
  }
  
  public static void selectDisplayComponents(Vector3f v, Vector3f v_display, Vector3f v_target){
    v_target.set(
      TOGGLE_SPATIAL_TRANSFORM ? v_display.x : v.x,
      TOGGLE_SPATIAL_TRANSFORM ? v_display.y : v.y,
      TOGGLE_TEMPORAL_TRANSFORM ? v_display.z : v.z
    );
  }
  
  public static void displayTransformBundle(Matrix3f m, Vector3f[] src, Vector3f[] dst) {
    for (int i=0; i<src.length; i++) {
      Relativity.displayTransform(m, src[i], dst[i]);
    }
  }
}

