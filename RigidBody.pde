// tflorez

class RigidBody {
  Particle parentParticle;
  ArrayList bodyParticles;
  ArrayList bodyVertices;
  
  RigidBody(Particle theParentParticle, Vector3f[] theBodyVertices) {
    this.parentParticle = theParentParticle;
    this.bodyVertices = new ArrayList();
    this.bodyParticles = new ArrayList();
    
    for (int i=0; i<theBodyVertices.length; i++) {
      this.bodyVertices.add(theBodyVertices[i]);
      this.bodyParticles.add(new RigidBodyParticle(this, theBodyVertices[i]));
    }
  }
  
  void drawGL(GL gl) {
    
    for (int i=0; i<=parentParticle.histCount; i++) {
      Frame frame = parentParticle.frameHist[i];
      
      gl.glColor4f(1.0, 0.9, 0.3, 0.3);
      drawBodyGL(gl, frame);
    }
  }
  
  Vector3f tmp1 = new Vector3f();
  Vector3f tmp2 = new Vector3f();
  
  /** Draw vertices of this rigid body as seen in rest coords of a frame.
   *  @param frame the rest frame to draw vertices of this rigidBody
   */
  void drawBodyGL(GL gl, Frame frame) {
    Vector3f drawVertex = tmp1;
    Vector3f toBpPrime = tmp2;
    
    Matrix3f parentLorentz = Relativity.getInverseLorentzTransformMatrix(frame.getVelocity());
    
    gl.glBegin(GL.GL_LINE_LOOP);
      
      for (Iterator iter=bodyParticles.iterator(); iter.hasNext(); ) {
        RigidBodyParticle bp = (RigidBodyParticle) iter.next();
        Vector3f toBp = bp.fromParent;
        
        // FRAME TO BP IN MODELSPACE
        parentLorentz.transform(toBp, toBpPrime);
        
        // MODEL ORIGIN TO BP
        toBpPrime.add(frame.getPositionVec());
        
        // DISPLAY TRANSFORM OF MODEL POS
        Relativity.displayTransform(lorentzMatrix, toBpPrime, drawVertex);
        gl.glVertex3f(drawVertex.x, drawVertex.y, drawVertex.z);
      }
    gl.glEnd();
  }
}

class RigidBodyParticle extends Particle {

  RigidBody parentBody;
  Vector3f fromParentVertex;
  Vector3f fromParent;
  ArrayList fromParentHist;

  RigidBodyParticle (RigidBody parentRigidBody, Vector3f fromParent) {
    fromParentHist = new ArrayList();
    
    addToHistory(fromParent);
    
    fromParentHist.add(fromParent);
    this.fromParent = fromParent;
  }
  
  void addToHistory(Vector3f theFromParent) {
    Vector3f fromParentCopy = new Vector3f(theFromParent);
    fromParentHist.add(fromParentCopy);
  }
}
