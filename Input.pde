// Input
// tflorez

// Input Device Vars
public boolean MOUSELOOK = false;
public boolean INPUT_RIGHT;
public boolean INPUT_LEFT;
public boolean INPUT_UP;
public boolean INPUT_DOWN;

class InputDispatch {
  
  ArrayList targets;
  
  float buttonPressure;
  float buttonAccumulateFactor = 0.02;
  float buttonDecayFactor = 0.95;
  
  InputDispatch(ArrayList targets) {
     this.targets = targets;
  }
  
  void update() {
    
    if (INPUT_UP || INPUT_DOWN || INPUT_LEFT || INPUT_RIGHT) {
      
      float x = 0;
      float y = 0;
      
      if      (INPUT_UP)   { y += -1.0; }
      else if (INPUT_DOWN) { y += +1.0; }
      else if (INPUT_LEFT) { x += -1.0; }
      else if (INPUT_RIGHT){ x += 1.0; }
      
      float direction = atan2(y, x);
      float offset = kamera.azimuth - HALF_PI;
      
      buttonPressure += (1 - buttonPressure) * buttonAccumulateFactor;
      constrain(buttonPressure, 0, 1.0);
      
      direction = direction + offset;
      
      if (prefs.getBoolean("1-D_control")) {
        direction = atan2( 0, cos(direction));
      }
      
      for (int i=0; i < targets.size(); i++) {
        
        if (prefs.getBoolean("energy_Conservation")) {
          energyNudge((Particle)targets.get(i), direction);
        }
        else {
          nudge((Particle)targets.get(i), direction, buttonPressure); 
        }
      }
    }
    else {
      buttonPressure *= buttonDecayFactor;
    }
    
    updateParticleDragging();
  }
  
  void energyNudge(Particle particle, float theta) {
    float energyAmt = (float) (0.01*particle.mass*C*C);
    particle.emitEnergy(energyAmt, theta+PI);
    
    intervalSay(45, "energyNudge(): energyAmt: " + energyAmt);
  }
  
  void nudge(Particle particle, float theta, float amt) {
      
      float momentumScale = 0.05;
      float momentumNudge = prefs.getFloat("momentumNudge");
      
      float v_mag = particle.velocity.magnitude;
      
      float p = (float) particle.getMomentum();
      
      float vx = targetParticle.velocity.vx;
      float vy = targetParticle.velocity.vy;
      
      float heading_initial = particle.velocity.direction;
      
      float angleDiff = heading_initial - theta;
      
      // Help user slow down at high speeds, quickly but smoothly
      if ((v_mag > 0.99999) && abs(abs(angleDiff)-PI) < TWO_PI/3.0) {
        theta = heading_initial + PI + angleDiff * (1.0 - v_mag);
        momentumScale = 0.10;
      }
  
      float dp = amt * (momentumScale * p + momentumNudge);
  
      float dp_x = dp * cos(theta);
      float dp_y = dp * sin(theta);
      
      particle.propelSelf(dp_x, dp_y);
  }
  
  boolean particleDragInProgress() {
    return ( dragInProgress && mouseButton == LEFT
             && !dragParticles.isEmpty() );
  }
  
  boolean holdingDragParticles() {
    return dragParticles != null && !dragParticles.isEmpty();
  }
  
  boolean shouldDropDragParticles() {
    return holdingDragParticles() && !dragInProgress;
  }
  
  void releaseDragParticles() {
    dragParticles = null;
  }
  
  void updateParticleDragging() {
    
    if ( particleDragInProgress() || holdingDragParticles() ) {
      if (clickedParticle == null) { return; }
      
      // GET INTERSECT WITH PLANE OF CLICKED DRAG PARTICLE
      Vector3f intersect = getMouseToParticlePlaneIntersect(clickedParticle);
      
      Vector3f offset = getOffset(clickedParticle.getPositionVec(), intersect);
      if (offset == null) { return; }
      
      // PREVIEW DROP POSITIONS FOR DRAG PARTICLES
      for (Iterator iter=dragParticles.iterator(); iter.hasNext(); ) {
        Particle p = (Particle) iter.next();
        if (p == null) { continue; }
        
        Vector3f previewPos = new Vector3f();
        previewPos.add(p.getPositionVec(), offset);
        
        // RENDER DRAGGED PARTICLE
        drawDragParticle(previewPos, p);
      }
      
      // DROP IF DRAG IS OVER
      if ( shouldDropDragParticles() ) {
        
        println("droppingDragParticles: offset" + offset + ", dragParticles: ");
        offsetParticles(offset, dragParticles);
        
        // RELEASE DRAG PARTICLES AFTER MOVE
        releaseDragParticles();
        
        // CLEAR CLICKED PARTICLE
        clickedParticle = null;
      }
    }
  }
  
  Vector3f getMouseToParticlePlaneIntersect(Particle theParticle) {
    if (theParticle == null) { return null; }
    
    Vector3f dragPointerDisplayPos = kamera.screenToModel(mouseX, mouseY);
    Vector3f dragPointerPos = Relativity.inverseDisplayTransform(targetParticle.velocity, dragPointerDisplayPos);
    
    Vector3f kameraPos = Relativity.inverseDisplayTransform(targetParticle.velocity, kamera.pos);
    
    Line dragLine = new Line();
    dragLine.defineBySegment(kameraPos, dragPointerPos);
    
    Plane clickedPlane = theParticle.getSimultaneityPlane();
    
    Vector3f intersect = new Vector3f();
    clickedPlane.getIntersection(dragLine, intersect);
    
    return intersect;
  }
  
  void drawDragParticle(Vector3f dragPos, Particle dragParticle) {
    
    Vector3f dragDisplayPos = new Vector3f();
    Relativity.displayTransform(lorentzMatrix, dragPos, dragDisplayPos);
    
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
      
      clickedParticle.drawHeadGL(gl, dragDisplayPos);
      
      DefaultFrame draggedFrame = clickedParticle.headFrame.clone();
      draggedFrame.setPosition(dragPos);
      
      myAxes.drawGL(gl, draggedFrame);

    pgl.endGL();
  }
}

Particle clickedParticle;

boolean isFanSelectionOpen() {
  return labelSelector.selection.contains(myFanSelection);
}

void openFanSelection(ISelectableLabel pickedSelectable) {
  
  List labels = new ArrayList();
  
  labels.add(new SelectableLabel("makeTargetParticle", pickedSelectable));
  labels.add(new SelectableLabel("attachRigidBody", pickedSelectable));
  
  if (getSelectedMeasurables().size() == 2) {
    labels.add(new SelectableLabel("measureDistance", pickedSelectable));
  }
  
  myFanSelection = new FanSelection( pickedSelectable, labels);
  labelSelector.addToSelectables(myFanSelection.getSelectableLabels());
  labelSelector.selection.add(myFanSelection);
}

void closeFanSelection() {
  labelSelector.drop(myFanSelection.getSelectableLabels());
  labelSelector.drop(myFanSelection);
}

// SelectableLabel Actions
void makeTargetParticle(Particle p) {
  addTarget(p);
  
  if (targetParticle != null) {
    targetParticle.headFrame.axesSettings = p.getAxesSettings();
  }
  p.headFrame.axesSettings = targetAxesSettings;
  targetParticle = p;
  
  setPlaneParent(targetParticle, simultIntersections);
}

void setPlaneParent(Particle parentPlane, List theIntersections) {
  for (int i=0; i<theIntersections.size(); i++) {
    PathPlaneIntersection intersection = (PathPlaneIntersection) theIntersections.get(i);
    intersection.setPlaneParent(parentPlane);
  }
}

// SelectableLabel Actions
void attachRigidBodies(Collection theParticleAttachTargets) {
  
  Dbg.say("attachRigidBodies(): attachTargets: " + theParticleAttachTargets);
  List bodies = buildRigidBodiesAt(buildRigidBodyVertices(), theParticleAttachTargets);
  addRigidBodies(bodies);
}

// SelectableLabel Actions
void measureDistance(Collection theSelectedMeasurables) {
  Iterator toMeasure = theSelectedMeasurables.iterator();
  
  ISelectableLabel from = (ISelectableLabel) toMeasure.next();
  ISelectableLabel to = (ISelectableLabel) toMeasure.next();
  
  topScene.addMeasurement(new DistanceMeasurement(from, to));
}

Collection getSelectedMeasurables() {
  
  List theSelectedMeasurables = new ArrayList(particleSelector.selection);
  theSelectedMeasurables.addAll(intersectionSelector.selection);
  
  return theSelectedMeasurables;
}

void mousePickedLabel(SelectableLabel sl) {
  
  String label = sl.getLabel();
  Selectable parentSelectable = sl.getParentSelectable();
  
  Dbg.say("mousePickedLabel(): " + label + ", parentSelectable: " + parentSelectable);
  
  Collection theSelectedMeasurables = getSelectedMeasurables();
  
  if (label == "makeTargetParticle" && parentSelectable instanceof Particle) {
    makeTargetParticle((Particle)parentSelectable);
  }
  else if (label == "attachRigidBody" && parentSelectable instanceof Particle) {
    
    Collection attachTargets = new HashSet();
    
    attachTargets.addAll(particleSelector.selection);
    attachTargets.add(parentSelectable);
    
    attachRigidBodies(attachTargets);
  }
  else if (label == "measureDistance" && theSelectedMeasurables.size() == 2) {
    
    measureDistance(theSelectedMeasurables);
  }
}

void mousePickedParticle(Particle pick) {
  
  clickedParticle = pick;
  
  if (mouseButton == RIGHT) {
    openFanSelection(pick);
  }
  else if (mouseButton == LEFT) {
    particleSelector.invertSelectionStatus(pick);
  }
}

void mousePickedIntersection(PathPlaneIntersection pick) {
  
  if (mouseButton == RIGHT) {
    openFanSelection(pick);
  }
  else if (mouseButton == LEFT) {
    intersectionSelector.invertSelectionStatus(pick);
  }
}

void mousePressedOnBackground() {
  if (mouseButton == LEFT) {
    particleSelector.clear();
    intersectionSelector.clear();
  }
  else if (mouseButton == RIGHT) {
    MOUSELOOK = !MOUSELOOK;
    
    if (MOUSELOOK) {
      cursor(MOVE);
    }
    else {
      cursor(ARROW);
    }
  }
}

void mousePressedOnScene() {
  
  Selectable pickedIntersection = (PathPlaneIntersection) intersectionSelector.pickPoint(kamera, mouseX, mouseY);
  Selectable pickedParticle = (Particle) particleSelector.pickPoint(kamera, mouseX, mouseY);
  Selectable pickedLabel = labelSelector.pickPoint(kamera, mouseX, mouseY);
  
  Selectable pick = (pickedLabel != null) ? pickedLabel : pickedParticle;
  pick = (pick != null) ? pick : pickedIntersection;
  
  Dbg.say("pick: " + pick + ", pickedLabel: " + pickedLabel);
  
  if (isFanSelectionOpen() && pickedLabel == null) {
    closeFanSelection();
  }
  else if (pick == null) {
    mousePressedOnBackground();
  }
  else if (pickedLabel != null && pickedLabel instanceof SelectableLabel) {
    mousePickedLabel((SelectableLabel)pickedLabel);
  }
  else if (pickedParticle != null) {
    mousePickedParticle((Particle)pickedParticle);
  }
  else if (pick instanceof PathPlaneIntersection) {
    mousePickedIntersection((PathPlaneIntersection) pickedIntersection);
  }
}

void mousePressedOnPane(Infopane clickedPane) {
  clickedPane.doClickAction();
}

void mousePressed() {
  
  //Dbg.say("mousePressed(): mouseX: " + mouseX + ", mouseY: " + mouseY);
  Infopane clickedPane = topScene.getClickedPane();
  Dbg.say("clickedPane: " + clickedPane );
  
  if (controlP5.window(this).isMouseOver()) {
    return;
  }
  else if ( clickedPane != null ) {
    mousePressedOnPane(clickedPane);
  }
  else {
    mousePressedOnScene();
  }
}

void mouseReleased() {
  
  dragInProgress = false;
}

Collection dragParticles;
boolean dragInProgress;

boolean isMouseOverControlP5() {
  return controlP5.window(this).isMouseOver();
}

boolean isMouseOverClickablePane() {
  return (topScene.getClickedPane() != null);
}

boolean isMouseOverGuiControl() {
  return isMouseOverControlP5() || isMouseOverClickablePane();
}

void mouseDragged() {
  
  if (!dragInProgress && mouseButton == LEFT && !isMouseOverGuiControl()
      && clickedParticle != null) {
      
      dragInProgress = true;
      
      println("mouseDragged(): ");
      println("  clickedParticle: " + clickedParticle);
      
      particleSelector.selection.add(clickedParticle);
      dragParticles = new HashSet(particleSelector.selection);
  }
}

void keyPressed() {
  
  switch (key) {
    case 'w' : INPUT_UP = true; break;
    case 'W' : INPUT_UP = true; break;
    case 'a' : INPUT_LEFT = true; break;
    case 'A' : INPUT_LEFT = true; break;
    case 's' : INPUT_DOWN = true; break;
    case 'S' : INPUT_DOWN = true; break;
    case 'd' : INPUT_RIGHT = true; break;
    case 'D' : INPUT_RIGHT = true; break;
  }
  switch (keyCode) {
    case UP : INPUT_UP = true; break;
    case DOWN : INPUT_DOWN = true; break;
    case LEFT : INPUT_LEFT = true; break;
    case RIGHT : INPUT_RIGHT = true; break;
  }
  
  if (key == ' ') {
    int i = (int) random(prefs.getInteger("PARTICLES"));
    targetParticle = (Particle) particles.get(i);
    addTarget((Particle)particles.get(i));
  }
  else if (key == '1') {
    particleSelector.clear();
  }
  else if (key == '`') {
    infolayerScene.infobox.toggleVisible();
  }
}

void keyReleased() {
  
  switch (key) {
    case 'w' : INPUT_UP = false; break;
    case 'W' : INPUT_UP = false; break;
    case 'a' : INPUT_LEFT = false; break;
    case 'A' : INPUT_LEFT = false; break;
    case 's' : INPUT_DOWN = false; break;
    case 'S' : INPUT_DOWN = false; break;
    case 'd' : INPUT_RIGHT = false; break;
    case 'D' : INPUT_RIGHT = false; break;
  }
  switch (keyCode) {
    case UP : INPUT_UP = false; break;
    case DOWN : INPUT_DOWN = false; break;
    case LEFT : INPUT_LEFT = false; break;
    case RIGHT : INPUT_RIGHT = false; break;
  }
}

