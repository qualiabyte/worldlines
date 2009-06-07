// Relativity
// tflorez

static class Relativity {
  static float C = 1.0f;

  public static float gamma(float v) {
    return 1.0f / (float)Math.sqrt (1 - v*v);
  }

  public static void lorentzTransform(float[] xyt, float[] vel, float[] xyt_prime) {

    loadVel(vel[0], vel[1]);
    lorentzTransformXYT(xyt, xyt_prime);
  }

  public static void lorentzTransformXYT(float[] xyt, float[] xyt_prime) {

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
    
    xt_prime[0] = gamma_v * (x - v_mag * t);
    xt_prime[1] = gamma_v * (t - v_mag * x / (C*C));
  }

  public static void applyTransforms(float[] xyt, float[] vel, float[] xyt_prime) {

    loadVel(vel[0], vel[1]);
    applyTransforms(xyt, xyt_prime);
  }

  public static void applyTransforms(float[] xyt, float[] xyt_prime) {

    lorentzTransformXYT(xyt, xyt_prime);

    xyt_prime[0] = TOGGLE_SPATIAL_TRANSFORM ? xyt_prime[0] : xyt[0];
    xyt_prime[1] = TOGGLE_SPATIAL_TRANSFORM ? xyt_prime[1] : xyt[1];
    xyt_prime[2] = TOGGLE_TEMPORAL_TRANSFORM ? xyt_prime[2] : xyt[2];
  }

  public static void loadVel(float vel_x, float vel_y) {
    vx = vel_x;
    vy = vel_y;

    v_mag = Math.max((float)Math.sqrt(vx*vx + vy*vy), 1E-7f);

    vx_norm = vx / v_mag;
    vy_norm = vy / v_mag;

    gamma_v = gamma(v_mag);
  }

  public static void loadObserver(float[] xyt) {
    System.arraycopy(xyt, 0, xyt_observer, 0, 3);
    
    float obs_x = xyt_observer[0];
    float obs_y = xyt_observer[1];
    float obs_t = xyt_observer[2];
  }

  static float[] xyt_observer = new float[3];
  static float[] XT_prime = new float[2];

  // PRELOAD VARS
  static float vx;
  static float vy;
  static float vx_norm;
  static float vy_norm;
  static float v_mag; 
  static float gamma_v;
  
  static float obs_x;
  static float obs_y;
  static float obs_t;

  // TRANSFORM MODE
  public static boolean TOGGLE_SPATIAL_TRANSFORM;
  public static boolean TOGGLE_TEMPORAL_TRANSFORM;
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
