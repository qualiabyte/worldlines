// Relativity
// tflorez

public static class Relativity {
  
  // TRANSFORM MODE
  
  /** For display transforms, controls whether to modify the spatial coordinates. */
  public static boolean TOGGLE_SPATIAL_TRANSFORM;
  
  /** For display transforms, controls whether to modify the time coordinate. */
  public static boolean TOGGLE_TEMPORAL_TRANSFORM;
  
  static float C = 1.0f;
  
  /** Get relativistic gamma for a given velocity magnitude, as a fraction of c. */
  public static float gamma(float v) {
    
    return 1.0f / (float) Math.sqrt(1 - v*v);
  }
  
  /**
   * Get the 1-dimensional Lorentz Matrix for a given Velocity.
   * @see #getLorentzTransformMatrix getLorentzTransformMatrix for the 2-D case, which is more useful.
   */
  public static Matrix3f getLorentzMatrix1D(Velocity v) {
    
    return new Matrix3f(
      v.gamma,              0,    -v.magnitude*v.gamma, // X
      0,                    1,    0,                    // Y
      -v.magnitude*v.gamma, 0,    v.gamma               // T
    );    
  }
  
  /**
   * Get the 1-dimensional Inverse Lorentz Matrix for a given Velocity.
   * This inverse matrix effectively "undoes" the 1D Lorentz transform.
   * @see #getInverseLorentzTransformMatrix getInverseLorentzTransformMatrix for the 2-D case, which is more useful.
   */
  public static Matrix3f getInverseLorentzMatrix1D(Velocity v) {
    
    return new Matrix3f(
      v.gamma,             0,    v.magnitude*v.gamma, // X
      0,                   1,    0,                   // Y
      v.magnitude*v.gamma, 0,    v.gamma              // T
    );
  }
  
  /** 
   * Get the matrix for an axis-angle rotation in 3-dimensions.
   * Formula courtesy of the OpenGL docs.
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
  
  /**
   * Rotate a matrix operation in the direction of a given velocity.
   * @param    toWrap  the matrix operation to wrap within a rotation.
   * @return           a new matrix operation formed by wrapping the original
   *                   within a rotation along the velocity's heading.
   */
  public static Matrix3f rotationWrapForHeading(Matrix3f toWrap, Velocity vel) {
    
    Matrix3f rotHeadingInverse = getRotationMatrix(-vel.direction, 0, 0, 1);
    Matrix3f rotHeading = getRotationMatrix(vel.direction, 0, 0, 1);
    
    Matrix3f M = new Matrix3f();
    M.set(rotHeading);
    M.mul(toWrap);
    M.mul(rotHeadingInverse);
    
    return M;
  }
  
  /** Get Lorentz Transform matrix for a velocity in 2 spatial dimensions. */
  public static Matrix3f getLorentzTransformMatrix(Velocity vel) {
    
    Matrix3f lorentz1D = getLorentzMatrix1D(vel);
    Matrix3f lorentz2D = rotationWrapForHeading( lorentz1D, vel );
    
    return lorentz2D;
  }
  
  /** Get Inverse Lorentz Transform Matrix for a velocity in 2 spatial dimensions. */
  public static Matrix3f getInverseLorentzTransformMatrix(Velocity vel) {
    
    Matrix3f inverseLorentz1D = getInverseLorentzMatrix1D(vel);
    Matrix3f inverseLorentz2D = rotationWrapForHeading( inverseLorentz1D, vel );
    
    return inverseLorentz2D;
  }
  
  /** Apply lorentz transform to a source vector, and store the result in a target vector. */
  public static void lorentzTransform(Velocity vel, Vector3f source, Vector3f target){
    
    Matrix3f M = getLorentzTransformMatrix(vel);
    M.transform(source, target);
  }
  
  /** Apply inverse lorentz transform to a source vector, and store the result in a target vector. */
  public static void inverseLorentzTransform(Velocity vel, Vector3f source, Vector3f target){
    
    Matrix3f M = getInverseLorentzTransformMatrix(vel);
    M.transform(source, target);
  }
  
  /** 
   * Apply the inverse lorentz transform for a velocity with 2 spatial dimensions to a (2+1) vector.
   * Returns a new vector for convenience.
   * @return    the inverse transformed vector.
   */
  public static Vector3f inverseLorentzTransform(Velocity vel, Vector3f v) {
    
    Vector3f v_prime = new Vector3f();
    inverseLorentzTransform(vel, v, v_prime);
    return v_prime;
  }
  
  /**
   * Get a matrix to reverse the display transform for a given velocity.
   * This is analogous to the inverse Lorentz matrix for motion in 1D,
   * but with the notion in mind that only certain components of the transform
   * were applied for the "display transform".
   */
  public static Matrix3f getInverseDisplayTransformMatrix1D(Velocity vel) {

    /* Inverting a display transform is a tricky case;
     * Getting the right inverse matrix depends on if the display transform
     * was applied to just the time coordinates, just the spatial coordinates,
     * both space and time (ie, a regular Lorentz transform was applied),
     * or neither (ie, no transform was applied).
     */

    Matrix3f m;

    if (TOGGLE_TEMPORAL_TRANSFORM && ! TOGGLE_SPATIAL_TRANSFORM) {
      m = new Matrix3f(
        1,                  0,              0,
        0,                  1,              0,
        vel.magnitude,      0,              1.0f / vel.gamma
      );
    }
    else if (TOGGLE_SPATIAL_TRANSFORM && ! TOGGLE_TEMPORAL_TRANSFORM) {
      m = new Matrix3f(
        1.0f / vel.gamma,   0,              vel.magnitude,
        0,                  1,              0,
        0,                  0,              1
      );
    }
    else if(TOGGLE_SPATIAL_TRANSFORM && TOGGLE_TEMPORAL_TRANSFORM) {
      m = getInverseLorentzMatrix1D(vel);
    }
    else {
      m = new Matrix3f(
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
      );
    }
    return m;
  }
  
  /** 
   * Inverse a display transformation applied to a vector.
   * @param    vel       The velocity which generated the Lorentz matrix used in the original transform.
   * @param    v_display The vector which resulted from the display transform.
   * @return             The "original" vector (ie, before the display transform was applied).
   */
  public static Vector3f inverseDisplayTransform(Velocity vel, Vector3f v_display) {
    
    Vector3f v_inverse = new Vector3f();
    
    Matrix3f inverseDisplay1D = getInverseDisplayTransformMatrix1D(vel);
    Matrix3f inverseDisplay2D = rotationWrapForHeading( inverseDisplay1D, vel );
    
    inverseDisplay2D.transform(v_display, v_inverse);
    
    return v_inverse;
  }
  
  /** 
   * Apply a display transform to a vector for a given velocity.
   * For convenience, the Lorentz matrix is generated from the velocity
   * and a new (display transformed) vector is returned.
   */
  public static Vector3f displayTransform(Velocity vel, Vector3f v) {
    
    Vector3f v_prime = new Vector3f();
    Matrix3f mLorentz = getLorentzTransformMatrix(vel);
    
    displayTransform(mLorentz, v, v_prime);

    return v_prime;
  }
  
  /** 
   * Apply a display transform to a vector for a given Lorentz matrix.
   * In a "display transform", the transformation is only actually applied to the enabled components.
   * That is, the spatial and temporal parts of the transform may be shown separately, together, or both off.
   * @see #TOGGLE_SPATIAL_TRANSFORM
   * @see #TOGGLE_TEMPORAL_TRANSFORM
   */
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
  
  /**
   * This convenience function is just a batch operation which applies
   * a display transform for a given matrix to a "bundle" of vectors.
   *
   * @param  m    The lorentz matrix passed to the display transform.
   * @param  src  The "bundle" is just a source array of arbitrary vectors.
   * @param  dst  Results are stored in the destination array.
   */
  public static void displayTransformBundle(Matrix3f m, Vector3f[] src, Vector3f[] dst) {
    for (int i=0; i<src.length; i++) {
      Relativity.displayTransform(m, src[i], dst[i]);
    }
  }
}

