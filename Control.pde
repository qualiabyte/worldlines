interface Control {
  String getLabel();
  Object getValue();
  void setValue(Object theValue);
}

class DefaultControl implements Control {
  String label;
  Object value;
  
  DefaultControl(String label, Object value) {
    this.label = label;
    this.value = value;
  }
  
  DefaultControl() {
  }
  
  void setLabel(String label) { this.label = label; }
  String getLabel() { return label; }
  Object getValue() { return value; }
  void setValue(Object theValue) { this.value = theValue; }
}

class FloatControl extends DefaultControl implements Control {
  
  float min;
  float max;
  
  FloatControl(String label, float value, float min, float max) {
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

class BooleanControl extends DefaultControl implements Control {
  
  BooleanControl(String label, Boolean value) {
    this.label = label;
    this.value = Boolean.valueOf(value);
  }
  
  void setValue(Boolean theValue) {
    this.value = Boolean.valueOf(theValue);
  }
}

class ControlPanel {
  ArrayList controls;
  String name;
  
  ControlPanel(String name) {
    this.name = name;
    controls = new ArrayList();
  }
  
  void addControl(Control c) {
    controls.add(c);
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
}

class ControlMap extends HashMap {
  
  Control getControl(String label) {
    return (Control) this.get(label);
  }
  
  void putControl(Control c) {
    this.put(c.getLabel(), c);
  }
  /*
  void putBooleanControl(BooleanControl) {
    this.put(BooleanControl.label, BooleanControl);
  }
  void putFloatControl(FloatControl) {
    this.put(FloatControl.label, FloatControl);
  }
  */
  BooleanControl getBooleanControl(String label) {
    return (BooleanControl) this.get(label);
  }
  
  FloatControl getFloatControl(String label) {
    return (FloatControl) this.get(label);
  }
  
  Boolean getBoolean(String label) {
    return (Boolean)((BooleanControl) this.get(label)).getValue();
  }
  
  Float getFloat(String label) {
    
    Control fc = (Control) this.get(label);
    return (Float) (fc).getValue();
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
}
