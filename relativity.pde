static class Relativity {

  // gamma(float v): get the time dilation factor (gamma) for given velocity (as fraction of c)
  static public float gamma(float v) {
    return 1.0 / sqrt (1 - v*v);
  }
  
  static public float gamma(PVector v) {
    return gamma(v.mag());
  }
}
