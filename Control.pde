// Control
// tflorez

interface Control {
  void addUpdater(Updater theUpdater);
  
  String getName();
  String getLabel();
  Object getValue();
  Updater getUpdater();
  
  void notifyUpdater();
  void setValue(Object theValue);
}

class DefaultControl implements Control {
  String name;
  String label;
  Object value;
  Updater updater;
  
  DefaultControl(String label, Object value) {
    this.name = label;
    this.label = label;
    this.value = value;
  }
  
  DefaultControl() { }
  
  String getName() { return name; }
  String getLabel() { return label; }
  Object getValue() { return value; }
  Updater getUpdater() { return this.updater; }
  
  void addUpdater(Updater updater) { this.updater = updater; }

  void setLabel(String label) { this.label = label; }  
  void setValue(Object value) {
    this.value = value;
    notifyUpdater();
  }
  void notifyUpdater() {
    if (updater != null) {
      updater.update(this.value);
    }
  }
}

class BooleanControl extends DefaultControl {
  
  BooleanControl(String label, Boolean value) {
    this.name = label;
    this.label = label;
    this.value = Boolean.valueOf(value);
  }
  
  void setValue(Boolean theValue) {
    this.value = Boolean.valueOf(theValue);
  }
}

class ButtonControl extends DefaultControl {
  ButtonControl(String label) {
    this.name = label;
    this.label = label;
    this.value = label;
  }
}

class StateControl extends DefaultControl {
  String state;
  HashMap stateLabels;
  
  StateControl(String name, String defaultState, String defaultLabel) {
    stateLabels = new HashMap();
    
    this.name = name;
    this.addState(defaultState, defaultLabel);
    this.setState(defaultState);
  }
  
  void addState(String state, String label) {
    stateLabels.put(state, label);
    //println("addState(" + state + ", " + label + ")");
    //println("  stateLabels.get(" + state + "): " + stateLabels.get(state));
  }
  
  void setState(String state) {
    this.state = state;
    this.label = (String) stateLabels.get(state);
    //println("setState(" + state + "): label: " +  (String)label);
  }
  
  String getState() {
    return this.state;
  }
  
  String getValue() {
    return (String) this.getState();
  }
}

class FloatControl extends DefaultControl {
  
  float min;
  float max;
  
  FloatControl(String label, float value, float min, float max) {
    this.name = label;
    this.label = label;
    this.value = new Float(value);
    this.min = min;
    this.max = max;
  }
  
  FloatControl(String label, float value) {
    this(label, value, 0, 1);
  }

  void setValue(float theValue) {
    this.value = Float.valueOf(theValue);
  }
}

class IntegerControl extends DefaultControl {
  int min;
  int max;
  
  IntegerControl(String label, int value, int min, int max) {
    this.name = label;
    this.label = label;
    this.value = new Integer(value);
    this.min = min;
    this.max = max;
  }
  
  IntegerControl(String label, int value) {
    this(label, value, 0, 1);
  }

  void setValue(int theValue) {
    this.value = Integer.valueOf(theValue);
  }
}

class ControlPanel {
  ArrayList controls;
  String name;
  String label;
  
  ControlPanel(String name) {
    this.name = name;
    this.label = name;
    controls = new ArrayList();
  }
  
  void setLabel(String label) {
    this.label = label;
  }
  
  Control addControl(Control c) {
    controls.add(c);
    return c;
  }
  
  Control putButton(String label) {
    ButtonControl c = new ButtonControl(label);
    return addControl(c);
  }
  
  Control putBoolean(String label, Boolean value) {
    Control c = new BooleanControl(label, value);
    return addControl(c);
  }
  
  Control putFloat(String label, float value) {
    Control c = new FloatControl(label, value);
    return addControl(c);
  }
  
  Control putFloat(String label, float value, float min, float max) {
    Control c = new FloatControl(label, value, min, max);    
    return addControl(c);
  }
  
  Control putInteger(String label, int value) {
    Control c = new IntegerControl(label, value);
    return addControl(c);
  }
  
  Control putInteger(String label, int value, int min, int max) {
    //println("putInteger: " + " " + value + " " + min + " " + max);
    Control c = new IntegerControl(label, value, min, max);
    return addControl(c);
  }
}

class ControlMap extends HashMap {
  HashMap controls;
  ArrayList controlPanels;
  
  ControlMap (ControlPanel[] controlPanels) {
    this.controls = this;
    this.controlPanels = new ArrayList(Arrays.asList(controlPanels));
    
    for (int i=0; i < controlPanels.length; i++) { 
      this.putControlPanel(controlPanels[i]);
    }
  }
  
  void putControlPanel (ControlPanel panel) {
    if (!controlPanels.contains(panel)) {
      this.controlPanels.add(panel);
    }
    this.putControls(panel.controls);
  }
  
  void putControls (List controls) {
    for (int i=0; i<controls.size(); i++) {
      Control c = (Control) controls.get(i);
      this.putControl(c);
    }
  }
  
  List getControls() {
    List theControlList = new ArrayList();
    
    for (Iterator iter=this.values().iterator(); iter.hasNext(); ) {
      Object value = iter.next();
      if (value instanceof Control) {
        theControlList.add(value);
      }
    }
    return theControlList;
  }
  
  Control getControl(String name) {
    Object c = this.get(name);
    return (c instanceof Control) ? (Control) c : null;
  }
  
  void putControl(Control c) {
    this.put(c.getName(), c);
  }
  
  BooleanControl getBooleanControl(String name) {
    return (BooleanControl) this.get(name);
  }
  
  FloatControl getFloatControl(String name) {
    return (FloatControl) this.get(name);
  }
  
  IntegerControl getIntegerControl(String name) {
    return (IntegerControl) this.get(name);
  }
  
  StateControl getStateControl(String name) {
    return (StateControl) this.get(name);
  }
  
  Boolean getBoolean(String name) {
    return (Boolean) getControl(name).getValue();
  }
  
  Float getFloat(String name) {
    return (Float) getControl(name).getValue();
  }
  
  Integer getInteger(String name) {
    return (Integer) getControl(name).getValue();
  }
  
  String getState(String stateName) {
    return (String) getControl(stateName).getValue();
  }
  
  String getString(String name) {
    
    Object s = this.get(name);
    return (s instanceof String) ? (String) s : null;
  }
  
  //void buildControlP5(ControlP5 theControlP5, ControlPanel[] theControlPanels) {
  void buildControlP5(ControlP5 theControlP5) {
    
    for (int panelIndex=0; panelIndex<controlPanels.size(); panelIndex++) {
      
      ControlPanel thePanel = (ControlPanel) controlPanels.get(panelIndex);
      println ("controlPanels.get("+panelIndex+"):"+ thePanel.name);
      
      String tabName = thePanel.name;
      String tabLabel = thePanel.label;
      
      theControlP5.addTab(tabName).setLabel(tabLabel);
      
      int bWidth = 25;
      int bHeight = 20;
      int bSpacingY = bHeight + 15;
      int sliderWidth = bWidth*5;
      
      int xOffsetGlobal = 10;
      
      int xPadding = 10;
      int yPadding = 15;
      
      int toggleWidth = 20;
      int toggleHeight = 20;
      
      int yOffsetGlobal = bHeight; //numGlobalControls*bSpacingY + bHeight;
      
      int xOffset = xOffsetGlobal;
      int yOffset = yPadding + yOffsetGlobal;
      
      for (int i=0; i<thePanel.controls.size(); i++) {
        Control control = (Control) thePanel.controls.get(i);
        
        Object prefValue = control.getValue();
        String name = control.getName();
        String label = control.getLabel();
        
        String className = prefValue.getClass().getName();
        //println("Controller for control('" + label + "' : " + prefValue + ") (" + className +")");
        
        if (prefValue instanceof java.lang.Boolean) {
          
          theControlP5.addToggle(label, (Boolean) prefValue, xOffset, yOffset, toggleWidth, toggleHeight).moveTo(tabName);
          yOffset += toggleHeight + yPadding;
        }
        else if (prefValue instanceof java.lang.Float) {
          
          float minValue = ((FloatControl)control).min;
          float maxValue = ((FloatControl)control).max;
          
          theControlP5.addSlider(label, minValue, maxValue, (Float) prefValue, xOffset, yOffset, sliderWidth, bHeight).moveTo(tabName);
          yOffset += bHeight + yPadding;
        }
        else if (prefValue instanceof java.lang.Integer) {
          
          float minValue = ((IntegerControl)control).min;
          float maxValue = ((IntegerControl)control).max;
          
          theControlP5.addSlider(label, minValue, maxValue, (Integer)prefValue, xOffset, yOffset, sliderWidth, bHeight).moveTo(tabName);
          yOffset += bHeight + yPadding;
        }
        else if (control instanceof ButtonControl) {
          
          theControlP5.addButton(label, 0, xOffset, yOffset, 2*bWidth, bHeight).moveTo(tabName);
          yOffset += bHeight + yPadding;
        }
        else if (control instanceof StateControl) {
          
          theControlP5.addButton(name, 0, xOffset, yOffset, 2*bWidth, bHeight).moveTo(tabName);
          controlP5.Button b = (controlP5.Button) theControlP5.controller(name);
          b.setLabel(label);
          yOffset += bHeight + yPadding;
        }
        
        //Dbg.say("Control:       " + control);
        //Dbg.say("Control label: " + label);
        //Dbg.say("Control name:  " + name);
        
        Controller addedController = theControlP5.controller(name);
        //Dbg.say("addedController: " + addedController);
        
        Updater updaterToAdd = control.getUpdater();
        if (updaterToAdd != null) {          
          addedController.addListener(new UpdaterControlListener(updaterToAdd));
        }
      }
    }
  }
  
  String lastControlEventLabel = "";
  float lastControlEventValue = 0;
  
  void handleControlEvent(controlP5.ControlEvent event) {
    
    Controller p5controller = event.controller();
    
    String name = p5controller.name();
    String label = p5controller.label();
    float controllerValue = p5controller.value();
    
    Control mappedControl = (Control) this.get(name);
    
//    if ( (label != lastControlEventLabel) || (controllerValue != lastControlEventValue) ) {
//      Dbg.say("ControlEvent : " + name + " '" + label + "', '" + controllerValue + "' (" + p5controller + ")");
//      lastControlEventLabel = label;
//      lastControlEventValue = controllerValue;
//    }
    
    if (mappedControl == null) {
      Dbg.warn("ControlEvent for controller '" + name + "', but mapped control is null");
    }
    else if (mappedControl instanceof BooleanControl 
          && p5controller instanceof controlP5.Toggle) {
      
      boolean newPrefValue = parseControlP5ToggleValue(controllerValue);
      mappedControl.setValue(newPrefValue);
    }
    else if (mappedControl instanceof IntegerControl
          && p5controller instanceof controlP5.Slider) {
      
      int newPrefValue = (int) controllerValue;
      mappedControl.setValue(newPrefValue);//this.getIntegerControl(label).setValue(newPrefValue);
      p5controller.setValueLabel(""+newPrefValue);
    }
    else if (mappedControl instanceof FloatControl
          && p5controller instanceof controlP5.Slider){
      
      //this.getFloatControl(label).setValue(controllerValue);
      mappedControl.setValue(controllerValue);
    }
    else if (mappedControl instanceof StateControl) {
      
      StateControl sc = (StateControl) mappedControl;
      p5controller.setLabel(sc.getLabel());
    }
  }
  
  void notifyAllUpdaters() {
    List controlList = this.getControls();
    for (Iterator iter=controlList.iterator(); iter.hasNext(); ) {
      Control c = (Control)iter.next();
      c.notifyUpdater();
    }
  }
}

// UPDATER AND CONTROL LISTENER
interface Updater {
  void update(Object updateValue);
  void addListenSource(ControlListener toAdd);
  List getListenSources();
}
class DefaultUpdater implements Updater {
  Object toUpdate;
  List listenSources = new ArrayList();
  
  DefaultUpdater(Object toUpdate) {
    this.toUpdate = toUpdate;
  }
  void update(Object updateValue) {}
  
  void addListenSource(ControlListener listenerSource) {
    listenSources.add(listenerSource);
  }
  List getListenSources() {
    return listenSources;
  }
}
class AxesSettingsVisibilityUpdater extends DefaultUpdater {
  
  AxesSettingsVisibilityUpdater(Object toUpdate) {
    super(toUpdate);
  }
  void update(Object updateValue) {
    ((AxesSettings)toUpdate).setAxesGridVisible((Boolean)updateValue);
//    Dbg.say("Updater: " + this);
//    Dbg.say("AxesSettings to update: " + this.toUpdate);
//    Dbg.say("AxesSettings of target: " + targetParticle.getAxesSettings());
  }
}
class UpdaterControlListener implements controlP5.ControlListener {
  /*
  Object objectToUpdate;
  Command updateCommand;
  
  SceneControlListener(Object theObjectToUpdate, Command theUpdateCommand) {
    toUpdate = theObjectToUpdate;
    updateCommand = theUpdateCommand;
  }
  */
  Updater updater;
  
  UpdaterControlListener(Updater theUpdater) {
    updater = theUpdater;
    theUpdater.addListenSource((controlP5.ControlListener)this);
  }
  public void controlEvent(ControlEvent theEvent) {
    
    Controller controller = theEvent.controller();
    Updater controllersUpdater = prefs.getControl(controller.name()).getUpdater();
    Dbg.say("controller: " + controller + "\n controller.name(): " + controller.name());
    
    if ( controllersUpdater != null) {
      if (controller instanceof controlP5.Toggle) {
        updater.update(parseControlP5Toggle((Toggle) controller));
      }
    }
  }
}

// COPY UTIL FOR CONTROLMAP
void copyControlValues(ControlMap source, ControlMap target) {
  for (Iterator iter=source.keySet().iterator(); iter.hasNext(); ) {
    String name = (String)iter.next();
    
    Control sourceControl = source.getControl(name);
    Control targetControl = target.getControl(name);
    
    if (sourceControl != null) {
      Object sourceValue = sourceControl.getValue();
      Object targetValue = targetControl.getValue();
        
      if (targetControl != null && sourceValue != null) {
        targetControl.setValue(sourceValue);
        
        if (!targetValue.equals(sourceValue)) {
          println("copying new value for control: " + name +
          ";\t(" + targetValue + "->" + sourceValue +")");
        }
      }
      else {
        Dbg.warn("  not copying value for control: " + name);
      }
    }
  }
}

// UTILITIES FOR CONTROLP5
Boolean float2Boolean(Float theFloat) {
  return (theFloat == 0) ? Boolean.FALSE : Boolean.TRUE;
}
Boolean parseControlP5ToggleValue(Float controllerValue) {
  return float2Boolean(controllerValue);
}
Boolean parseControlP5Toggle(Toggle t) {
  return parseControlP5ToggleValue(t.value());
}
