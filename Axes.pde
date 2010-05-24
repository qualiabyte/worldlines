// Axes
// tflorez

class AxesSettings {
  
  boolean axesVisible = true;
  boolean axesLabelsVisible = false;
  boolean axesGridVisible = false;
  boolean simultaneityPlaneVisible = true;
  
  void setAllVisibility(boolean b) {
    this.setAxesVisible(b);
    this.setAxesLabelsVisible(b);
    this.setAxesGridVisible(b);
    this.setSimultaneityPlaneVisible(b);
  }
  
  boolean axesVisible() {
    return this.axesVisible;
  }
  
  void setAxesVisible(boolean axesVisible) {
    this.axesVisible = axesVisible;
  }
  
  boolean axesLabelsVisible() {
    return this.axesLabelsVisible;
  }
  
  void setAxesLabelsVisible(boolean axesLabelsVisible) {
    this.axesLabelsVisible = axesLabelsVisible;
  }
  
  boolean axesGridVisible() {
    return this.axesGridVisible;
  }
  
  void setAxesGridVisible(boolean axesGridVisible) {
    this.axesGridVisible = axesGridVisible;
  }
  
  boolean simultaneityPlaneVisible() {
    return this.simultaneityPlaneVisible;
  }
  
  void setSimultaneityPlaneVisible(boolean simultVisible) {
    this.simultaneityPlaneVisible = simultVisible;
  }
}

class Axes {

  Frame frame;

  float numGridLines = 10;
  float gridLineSpacing = 10;
  float gridBoundary = 100;
  float axisBoundary = 10;
  float basisLabelBoundary = 10;

  String gridUnits = "ls";
  
  String[] restFrameBasisLabels = new String[] { "x", "y", "ct" };
  String[] axesFrameBasisLabels = new String[] { "x'", "y'", "ct'" };

  Vector3f[] restFrameBasis = new Vector3f[] { new Vector3f(1,0,0), new Vector3f(0,1,0), new Vector3f(0,0,1) };
  Vector3f[] restFrameDisplayBasis = new Vector3f[] { new Vector3f(), new Vector3f(), new Vector3f() };
  Vector3f[] axesFrameDisplayBasis = new Vector3f[] { new Vector3f(), new Vector3f(), new Vector3f() };
  
  float[][] axisColors = new float[][] {
    {1.0, 0.5, 0.5, 0.6},
    {0.5, 0.5, 1.0, 0.6},
    {0.15, 0.9, 1.0, 0.6},
  };
  
  void setGridLineSpacing(float spacing) {
    this.gridLineSpacing = spacing;
    this.numGridLines = gridBoundary / gridLineSpacing;
  }
  
  void setGridBoundary(float boundary) {
    this.gridBoundary = boundary;
    this.gridLineSpacing = gridBoundary / numGridLines;
  }
  
  void setAxisBoundary(float boundary) {
    this.axisBoundary = boundary;
  }
  
  Axes() {
  }
  
  Axes(Frame f) {
    this.frame = f;
  }
    
  void drawGL(GL gl) {
    drawGL(gl, this.frame);
  }
  
  void drawGL(GL gl, Frame f) {
    drawAxesGL(gl, f);
  }
  
  void drawAxesGL(GL gl, Frame f) {
    
    AxesSettings frameSettings = f.getAxesSettings();
    
    if (!frameSettings.axesVisible()) {
      return;
    }
    
    Vector3f pos = f.getDisplayPositionVec();
    Velocity vel = f.getVelocity();
    
    // DRAW AXES FRAME BASIS
    Relativity.displayTransformBundle(lorentzMatrix, vel.basisInverse, axesFrameDisplayBasis);
    drawBasis(pos, axesFrameDisplayBasis, axisColors, frameSettings.axesLabelsVisible, axesFrameBasisLabels);
    
    // REST FRAME BASIS    
    Relativity.displayTransformBundle(lorentzMatrix, restFrameBasis, restFrameDisplayBasis);
    drawBasis(pos, restFrameDisplayBasis, axisColors, frameSettings.axesLabelsVisible, restFrameBasisLabels);
    
    // AXES FRAME XY (SIMULTANEITY) PLANE
    if (frameSettings.simultaneityPlaneVisible()) {
      drawPlane(pos, axesFrameDisplayBasis[0], axesFrameDisplayBasis[1]);
    }
    
    // AXES FRAME GRID LINES
    if (frameSettings.axesGridVisible) {
      
      float kamToAxesDist = getDistance(kamera.pos, f.getDisplayPositionVec());
      
      setGridBoundary( max(100, kamToAxesDist) );
      setGridLineSpacing( max(10, nearestPowerOf10Below(kamToAxesDist * 0.5)) );
      
      drawGrid(pos, axesFrameDisplayBasis[0], axesFrameDisplayBasis[2], axisColors[0], axisColors[2], true);
    }
  }

  void drawBasisLabels(Vector3f pos, Vector3f[] theBasis, float[][] theBasisColors, String[] theBasisLabels) {
    Vector3f labelPos = new Vector3f();
    
    for (int i=0; i<3; i++) {
      labelPos.scaleAdd(1.5*axisBoundary, theBasis[i], pos);
      myLabelor.vtext.setColor(theBasisColors[i][0], theBasisColors[i][1], theBasisColors[i][2], theBasisColors[i][3] + 0.3);
      myLabelor.drawLabelGL(gl, theBasisLabels[i], labelPos, 0.5);
    }
  }
  
  void drawBasis(Vector3f pos, Vector3f[] theBasis, float[][] theBasisColors, boolean drawLabels, String[] theBasisLabels) {
    
    if (drawLabels) {
      drawBasisLabels(pos, theBasis, theBasisColors, theBasisLabels);
    }
    
    gl.glLineWidth(2);
    gl.glBegin(GL.GL_LINES);
    for (int i=0; i<3; i++) {
      gl.glColor4fv(theBasisColors[i], 0);
      gl.glVertex3f(pos.x, pos.y, pos.z);
      gl.glVertex3f(
        pos.x + axisBoundary * theBasis[i].x,
        pos.y + axisBoundary * theBasis[i].y,
        pos.z + axisBoundary * theBasis[i].z);
    }
    gl.glEnd();
  }
  
  void drawPlane(Vector3f pos, Vector3f v1, Vector3f v2) {
    Vector3f tmp = new Vector3f();
    
    gl.glBegin(GL.GL_QUADS);
      tmp.set(pos); gl.glVertex3f(pos.x, pos.y, pos.z);
      tmp.scaleAdd( axisBoundary, v1, tmp); gl.glColor4f(1.0, 0.5, 0.5, 0.3); gl.glVertex3f(tmp.x, tmp.y, tmp.z);
      tmp.scaleAdd( axisBoundary, v2, tmp); gl.glColor4f(0.1, 0.1, 0.1, 0.1); gl.glVertex3f(tmp.x, tmp.y, tmp.z);
      tmp.scaleAdd(-axisBoundary, v1, tmp); gl.glColor4f(0.5, 0.5, 1.0, 0.3); gl.glVertex3f(tmp.x, tmp.y, tmp.z);
    gl.glEnd();
  }

  void drawGridLabel(Vector3f theGridOrigin, Vector3f theGridDisplayBasis, float theGridCoordinate, float[] labelColor) {
    
    Vector3f labelPos = new Vector3f();
    labelPos.scaleAdd(theGridCoordinate, theGridDisplayBasis, theGridOrigin);
    myLabelor.vtext.setColor(labelColor[0] + 0.3, labelColor[1] + 0.3, labelColor[2] + 0.3, labelColor[3] + 0.3);
    myLabelor.drawLabelGL(gl, "" + nf(theGridCoordinate, 0, 0) + this.gridUnits, labelPos, 0.5);
  }
  
  void drawGrid(Vector3f pos, Vector3f v1, Vector3f v2, float[] color1, float[] color2, Boolean drawLabels) {
    
    if (drawLabels) {
      
      for (int i=1; pow(10, i) < this.gridBoundary; i++) {
        for (int j=1; j<=2; j++) {
          drawGridLabel(pos, v1, 5*j*pow(10, i), color1 );
        }
      }
      
      drawGridLabel(pos, v1, numGridLines * gridLineSpacing, color1);
      drawGridLabel(pos, v2, numGridLines * gridLineSpacing, color2);
    }
    
    Vector3f[] gridBasis = new Vector3f[] { v1, v2 };
    float[][] gridColors = new float[][] { color1, color2 };
    
    Vector3f lineStart = new Vector3f();
    Vector3f lineEnd = new Vector3f();
    
    gl.glBegin(GL.GL_LINES);
    for (int i=0; i<gridBasis.length; i++) {
    
      Vector3f lineBasis = gridBasis[i];
      Vector3f spacingBasis = gridBasis[ (i==0) ? 1 : 0 ];
      
      gl.glColor4fv(gridColors[i], 0);
      
      for (int j=0; j<numGridLines; j++) {
        
        lineStart.scaleAdd(j * gridLineSpacing, spacingBasis, pos);
        
        lineEnd.scaleAdd(1 * numGridLines * gridLineSpacing, lineBasis, lineStart);
                
        gl.glVertex3f(lineStart.x, lineStart.y, lineStart.z);

        gl.glColor4fv(gridColors[i], 0);
        gl.glVertex3f(lineEnd.x, lineEnd.y, lineEnd.z);
      }
    }
    gl.glEnd();
  }
}

