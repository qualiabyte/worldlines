// Relativity
// tflorez

static class Relativity {
  static float C = 1.0f;

  public static float gamma(float v) {
    return 1.0f / (float) Math.sqrt(1 - v*v);
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
  /*
  public static Matrix3f getLorentzInverseDisplayMatrix(){
    
    Matrix3f M = getLorentzInverseMatrix();
    
    if (TOGGLE_SPATIAL_TRANSFORM) {
      //M[1][0] = 0;
      //M[1][1] = 1;
      
      M.setRow(0, 1, 0, 0);
    }
    
    if (TOGGLE_TEMPORAL_TRANSFORM) {
      //M[0][0] = 1;
      //M[0][1] = 0;
      
      M.setRow(2, 0, 0, 1);
    }
    
    return M;
  }
  */
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
  /*
  public static void applyInverseDisplayTransforms(float[] xyt, float[] xyt_prime) {
    Vector3f xyt_v3f = new Vector3f(xyt);
    Vector3f xyt_prime_v3f = new Vector3f();
    
    float heading = atan2(v.vy, v.vx);
    
    Matrix3f rotHeadingInv = getRotationMatrix(-heading, 0, 0, 1);
    Matrix3f lorentzInverse = getLorentzInverseDisplayMatrix();
    Matrix3f rotHeading = getRotationMatrix(heading, 0, 0, 1);
    
    Matrix3f inverseDisplayMatrix = new Matrix3f();
    
    inverseDisplayMatrix.set(rotHeading);
    inverseDisplayMatrix.mul(lorentzInverse);
    inverseDisplayMatrix.mul(rotHeadingInv);

    inverseDisplayMatrix.transform(xyt_v3f, xyt_prime_v3f);
    
    xyt_prime_v3f.get(xyt_prime);
  }
  */
  public static Vector3f inverseTransform(Velocity vel, Vector3f xyt_v3f) {

    loadVelocity(vel);
    Vector3f xyt_prime_v3f = new Vector3f();
    
    Matrix3f rotHeadingInverse = getRotationMatrix(-v.direction, 0, 0, 1);
    Matrix3f lorentzInverse = getLorentzInverseMatrix();
    Matrix3f rotHeading = getRotationMatrix(v.direction, 0, 0, 1);
    
    Matrix3f M = new Matrix3f();
    M.set(rotHeading);
    M.mul(lorentzInverse);
    M.mul(rotHeadingInverse);
    
    M.transform(xyt_v3f, xyt_prime_v3f);
    
    return xyt_prime_v3f;
  }
  
  public static float[] inverseTransform(Velocity vel, float[] xyt) {
    
    float[] xyt_prime = new float[3];
    
    Vector3f xyt_v3f = new Vector3f(xyt);    
    
    inverseTransform(vel, xyt_v3f).get(xyt_prime);
    
    return xyt_prime;
  }
  
  public static float[] inverseDisplayTransform(Velocity vel, float[] xyt) {
    
    return selectInverseDisplayComponents(xyt, inverseTransform(vel, xyt));
  }
  /*
    loadVelocity(vel);
    
    float[] xyt_prime = inverseTransform(vel, xyt);
    selectInverseDisplayComponents(xyt, xyt_prime, xyt_prime);
    
    return xyt_prime;
  }
  */
  
  public static void transform(Velocity vel, Vector3f xyt_v3f, Vector3f target){
    
    loadVelocity(vel);
    //Vector3f xyt_prime_v3f = new Vector3f();
    
    Matrix3f rotHeadingInverse = getRotationMatrix(-v.direction, 0, 0, 1);
    Matrix3f lorentz = getLorentzMatrix();
    Matrix3f rotHeading = getRotationMatrix(v.direction, 0, 0, 1);
    
    Matrix3f M = new Matrix3f();
    M.set(rotHeading);
    M.mul(lorentz);
    M.mul(rotHeadingInverse);
    
    M.transform(xyt_v3f, target);
  }
  
  public static Vector3f displayTransform(Velocity vel, Vector3f v) {
    Vector3f v_prime = new Vector3f();
    
    transform(vel, v, v_prime);
    selectDisplayComponents(v, v_prime, v_prime);
    
    return v_prime;
  }
  
  public static float[] transform(Velocity vel, float[] xyt) {
    
    loadVelocity(vel);
    
    Vector3f v = new Vector3f(xyt);
    Vector3f v_prime = new Vector3f();
    
    transform(vel, v, v_prime);
    
    float[] xyt_prime = new float[3];
    
    v_prime.get(xyt_prime);
    
    return xyt_prime;
  }
  
  public static float[] displayTransform(Velocity vel, float[] xyt) {
    
    loadVelocity(vel);
    
    float[] xyt_prime = transform(vel, xyt);
    selectDisplayComponents(xyt, xyt_prime, xyt_prime);
    
    return xyt_prime;
  }
  
  public static void selectDisplayComponents(Vector3f v, Vector3f v_prime, Vector3f v_target){
    v_target.set(
      TOGGLE_SPATIAL_TRANSFORM ? v_prime.x : v.x,
      TOGGLE_SPATIAL_TRANSFORM ? v_prime.y : v.y,
      TOGGLE_TEMPORAL_TRANSFORM ? v_prime.z : v.z
    );
  }
  
  public static float[] selectDisplayComponents(float[] xyt, float[] xyt_prime){
    float[] xyt_target = new float[3];
    selectDisplayComponents(xyt, xyt_prime, xyt_target);
    return xyt_target;    
  }
  
  public static float[] selectInverseDisplayComponents(float[] xyt, float[] xyt_prime){
    float[] xyt_target = new float[3];
    selectInverseDisplayComponents(xyt, xyt_prime, xyt_target);
    return xyt_target;    
  }
  
  public static void selectDisplayComponents(float[] xyt, float[] xyt_prime, float[] xyt_target){
    xyt_target[0] = TOGGLE_SPATIAL_TRANSFORM ? xyt_prime[0] : xyt[0];
    xyt_target[1] = TOGGLE_SPATIAL_TRANSFORM ? xyt_prime[1] : xyt[1];
    xyt_target[2] = TOGGLE_TEMPORAL_TRANSFORM ? xyt_prime[2] : xyt[2];
  }
  
  public static void selectInverseDisplayComponents(float[] xyt, float[] xyt_prime, float[] xyt_target){
    xyt_target[0] = TOGGLE_SPATIAL_TRANSFORM ? xyt[0] : xyt_prime[0];
    xyt_target[1] = TOGGLE_SPATIAL_TRANSFORM ? xyt[1] : xyt_prime[1];
    xyt_target[2] = TOGGLE_TEMPORAL_TRANSFORM ? xyt[2] : xyt_prime[2];
  }
  
/*
  public static void lorentzTransform(float[] xyt, float[] vel, float[] xyt_prime) {

    loadVel(vel[0], vel[1]);
    lorentzTransformXYT(xyt, xyt_prime);
  }
*/
  public static void lorentzTransformXYT(float[] xyt, float[] xyt_prime) {

    float rx = xyt[0];// - obs_x;
    float ry = xyt[1];// - obs_y;
    float t =  xyt[2];// - obs_t;

    float r_dot_v = rx * v.vx + ry * v.vy;

    // Projection |r| Cos(angle) gives the component of r parallel to v
    float r_cos_theta = r_dot_v / v.magnitude;
    
    float vx_norm = v.vx / v.magnitude;
    float vy_norm = v.vy / v.magnitude;

    // Get components of r parallel and perpendicular to v
    float r_para_x = r_cos_theta * vx_norm;
    float r_para_y = r_cos_theta * vy_norm;

    float r_perp_x = rx - r_para_x;
    float r_perp_y = ry - r_para_y;

    float r_para_mag = (float) Math.sqrt(r_para_x * r_para_x + r_para_y * r_para_y);

    // 1D Transform on part of r parallel to velocity, store in XT_prime
    lorentzTransformXT(r_cos_theta, t, XT_prime);

    float X = XT_prime[0];
    float T = XT_prime[1];

    float r_para_x_final = vx_norm * X;
    float r_para_y_final = vy_norm * X;

    xyt_prime[0] = r_perp_x + r_para_x_final;
    xyt_prime[1] = r_perp_y + r_para_y_final;
    xyt_prime[2] = T;
  }

  public static void lorentzTransformXT(float x, float t, float[] xt_prime) {

    xt_prime[0] = v.gamma * (x - v.magnitude * t);
    xt_prime[1] = v.gamma * (t - v.magnitude * x / (C*C));
  }
/*
  public static void applyTransforms(float[] xyt, float[] vel, float[] xyt_prime) {

    loadVel(vel[0], vel[1]);
    applyTransforms(xyt, xyt_prime);
  }
*/
  public static void applyTransforms(float[] xyt, float[] xyt_prime) {

    lorentzTransformXYT(xyt, xyt_prime);

    xyt_prime[0] = TOGGLE_SPATIAL_TRANSFORM ? xyt_prime[0] : xyt[0];
    xyt_prime[1] = TOGGLE_SPATIAL_TRANSFORM ? xyt_prime[1] : xyt[1];
    xyt_prime[2] = TOGGLE_TEMPORAL_TRANSFORM ? xyt_prime[2] : xyt[2];
  }

  public static void loadVelocity(Velocity velocity) {
    v = velocity;
    
    float vx = v.vx;
    float vy = v.vy;
    
    float v_mag = Math.max((float)Math.sqrt(vx*vx + vy*vy), 1E-7f);
    float beta = v_mag;
    
    vx_norm = vx / v_mag;
    vy_norm = vy / v_mag;
    //loadVel(velocity.vx, velocity.vy);
  }

  public static void loadFrame(Frame f) {
    //float[] vel = f.getVelocity();
    float[] pos = f.getPosition();
    
    Velocity vel = f.getVelocity();
    loadVelocity(vel);
    //loadVel(velocity.vx, velocity.vy);
    
    obs_x = xyt_observer[0];
    obs_y = xyt_observer[1];
    obs_t = xyt_observer[2];
  }

/*
  public static void loadVel(float vel_x, float vel_y) {
    vx = vel_x;
    vy = vel_y;
    
    //v = new Velocity(vel_x, vel_y);
    
    float v_mag = Math.max((float)Math.sqrt(vx*vx + vy*vy), 1E-7f);
    float beta = v_mag;
    
    vx_norm = vx / v_mag;
    vy_norm = vy / v_mag;
    
    //float gamma = gamma(v_mag);
  }
*/
/*
  public static void loadObserver(float[] xyt) {
    
    System.arraycopy(xyt, 0, xyt_observer, 0, 3);

    float obs_x = xyt_observer[0];
    float obs_y = xyt_observer[1];
    float obs_t = xyt_observer[2];
  }
*/
  static float[] xyt_observer = new float[3];
  static float[] XT_prime = new float[2];

  static Velocity v;
  
  // PRELOAD VARS
  
  //static float vx;
  //static float vy;
  static float vx_norm;
  static float vy_norm;
  //static float v_mag, beta;
  //static float gamma;

  // Normal to surface of simult.
  // Pvector simult_norm;

  static float obs_x;
  static float obs_y;
  static float obs_t;

  // TRANSFORM MODE
  public static boolean TOGGLE_SPATIAL_TRANSFORM;
  public static boolean TOGGLE_TEMPORAL_TRANSFORM;
  public static float seconds;
}


/* Variation on lorentzTransform which tries to transform the x and y components separately
 // Had a bug earlier, may be fixed now
 
 public static void lorentzTransform(float[] xyt, float[] xyt_prime) {
 //float obs_dot_v = obs_x * vx + obs_y * vy;
 //float obs_cos_theta = obs_dot_v / v_mag;
 
 float rx = xyt[0];
 float ry = xyt[1];
 float t =  xyt[2];
 
 float r_dot_v = rx * vx + ry * vy;
 
 // Projection |r| Cos(angle) gives the component of r parallel to v
 float r_cos_theta = r_dot_v / v_mag;
 
 // Get components of r parallel and perpendicular to v
 float r_para_x = r_cos_theta * vx_norm;
 float r_para_y = r_cos_theta * vy_norm;
 
 float r_perp_x = rx - r_para_x;
 float r_perp_y = ry - r_para_y;
 
 float r_para_x_final = gamma_v * (r_para_x - vx_norm * v_mag * t);
 float r_para_y_final = gamma_v * (r_para_y - vy_norm * v_mag * t);
 
 xyt_prime[0] = r_perp_x + r_para_x_final;
 xyt_prime[1] = r_perp_y + r_para_y_final;
 xyt_prime[2] = gamma_v * (t - v_mag * r_cos_theta / (C*C));
 }
 */

