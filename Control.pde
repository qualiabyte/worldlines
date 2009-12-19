// tflorez

interface Control {
  String getName();
  String getLabel();
  Object getValue();
  void setValue(Object theValue);
}

class DefaultControl implements Control {
  String name;
  String label;
  Object value;
  
  DefaultControl(String label, Object value) {
    this.name = label;
    this.label = label;
    this.value = value;
  }
  
  DefaultControl() { }
  
  String getName() { return name; }
  String getLabel() { return label; }
  Object getValue() { return value; }

  void setLabel(String label) { this.label = label; }  
  void setValue(Object value) { this.value = value; }
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
    println("addState(" + state + ", " + label + ")");
    //println("  stateLabels.get(" + state + "): " + stateLabels.get(state));
  }
  
  void setState(String state) {
    this.state = state;
    this.label = (String) stateLabels.get(state);
    println("setState(" + state + "): label: " +  (String)label);
  }
  
  String getState() {
    return this.state;
  }
  
  String getValue() {
    return this.getState();
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
  
  void addControl(Control c) {
    controls.add(c);
  }
  
  ButtonControl putButton(String label) {
    ButtonControl c = new ButtonControl(label);
    addControl(c);
    return c;
  }
  
  void putBoolean(String label, Boolean value) {
    Control c = new BooleanControl(label, value);
    addControl(c);
  }
  
  void putFloat(String label, float value) {
    Control c = new FloatControl(label, value);
    addControl(c);
  }
  
  void putFloat(String label, float value, float min, float max) {
    Control c = new FloatControl(label, value, min, max);    
    addControl(c);
  }
  
  void putInteger(String label, int value) {
    Control c = new IntegerControl(label, value);
    addControl(c);
  }
  
  void putInteger(String label, int value, int min, int max) {
    println("putInteger: " + " " + value + " " + min + " " + max);
    Control c = new IntegerControl(label, value, min, max);
    addControl(c);
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
  
  void putControls (java.util.List controls) {
    for (int i=0; i<controls.size(); i++) {
      Control c = (Control) controls.get(i);
      this.putControl(c);
    }
  }
  
  Control getControl(String label) {
    return (Control) this.get(label);
  }
  
  void putControl(Control c) {
    this.put(c.getName(), c);
  }
  
  BooleanControl getBooleanControl(String label) {
    return (BooleanControl) this.get(label);
  }
  
  FloatControl getFloatControl(String label) {
    return (FloatControl) this.get(label);
  }
  
  IntegerControl getIntegerControl(String label) {
    return (IntegerControl) this.get(label);
  }
  
  Boolean getBoolean(String label) {
    return (Boolean)((BooleanControl) this.get(label)).getValue();
  }
  
  Float getFloat(String label) {
    
    Control c = (Control) this.get(label);
    return (Float) c.getValue();
  }
  
  Integer getInteger(String label) {
    
    Control c = (Control) this.get(label);
    return (Integer) c.getValue();
  }
  
  String getState(String stateName) {
    
    StateControl c = (StateControl) this.get(stateName);
    return (String) c.getState(); //println("getState(" + stateName + "): " + c.getState()); 
  }
  
  String getString(String label) {
    
    Object stringObj = this.get(label);
    
    if (stringObj instanceof String) {
      return (String) stringObj;
    }
    else {
      return null;
    }
  }
  
   void buildControlP5(ControlP5 theControlP5) {
  //void buildControlP5(ControlP5 theControlP5, ControlPanel[] theControlPanels) {
    
    //ControlP5 controlP5 = new ControlP5(theParentPApplet);
    
    // BUILD CONTROLP5
    for (int panelIndex=0; panelIndex<controlPanels.size(); panelIndex++) {
    //for (int panelIndex=0; panelIndex<theControlPanels.length; panelIndex++) {
      
      ControlPanel thePanel = (ControlPanel) this.controlPanels.get(panelIndex);
      println ("controlsPanels.get("+panelIndex+"):"+ thePanel.name);
      //ControlPanel thePanel = (ControlPanel) theControlPanels[panelIndex];
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
        println("Controller for control('" + label + "' : " + prefValue + ") (" + className +")");
        
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
      Dbg.warn("Controller '" + label + "' failed assignment to null preference '" + label + "'");
    }
    else if (p5controller instanceof controlP5.Toggle) {
      
      boolean newPrefValue = (controllerValue == 0) ? false : true;
      mappedControl.setValue(newPrefValue);
      
      //Dbg.say("this.get('" + label + "') now: " + this.get(label));
    }
    else if (p5controller instanceof controlP5.Slider 
          && mappedControl instanceof IntegerControl) {
      
      int newPrefValue = (int) controllerValue;
      ((IntegerControl) mappedControl).setValue(newPrefValue);//this.getIntegerControl(label).setValue(newPrefValue);
      p5controller.setValueLabel(""+newPrefValue);
    }
    else if (p5controller instanceof controlP5.Slider 
          && mappedControl instanceof FloatControl){
      
      this.getFloatControl(label).setValue(controllerValue);
    }
    else if (mappedControl instanceof StateControl) {
      
      StateControl sc = (StateControl) mappedControl;
      p5controller.setLabel(sc.getLabel());
    }
  }
}

