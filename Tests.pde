// Tests
// tflorez

import java.util.ArrayList;

void runTests() {

  Tester tester = new Tester("RelativityTests", 7);
  tester.verbose = false;
  
  // Sanity Check
  tester.ok(1 == 1, "Sanity check: 1 == 1");
  
  // Use velocity of 0.9 c in x-direction
  Velocity vel = new Velocity(0.9f, 0);

  // Use vector (1, 0, 0)
  Vector3f v1 = new Vector3f(1, 0, 0);

  // Do Lorentz transformation
  Vector3f vLorentz = new Vector3f();
  Relativity.lorentzTransform(vel, v1, vLorentz);
  
  // Test Gamma
  float gamma = 1.0f / (float) Math.sqrt(1 - pow(0.9f, 2));
  
  tester.ok( vel.gamma == gamma
             && abs(gamma - 2.29416) < 0.01,
             "Gamma(0.9 c) should be: 2.29416" );
  
  // Calculate expectation value for vector 1, 0, 0
  float xprime = gamma * (v1.x - 0);
  float tprime = gamma * (0 - vel.vx * v1.x);
  
  Vector3f vExpect = new Vector3f(xprime, 0, tprime);
  Vector3f vExpectByHand = new Vector3f(2.29416, 0, -2.06474);
  
  // Test the calculated expectation value against the raw numbers we expect
  tester.ok( abs(getDistance(vExpect, vExpectByHand)) < 0.01,
             "Expected lorentz transform vector should match what we calculated by hand" );
  
  
  // Test the Lorentz Transform
  tester.ok( getDistance(vLorentz, vExpect) < 0.01,
             "Lorentz transform of (1, 0, 0) with vel.x = 0.9 c should be: (2.29416, 0, -2.06474)",
               "vLorentz:\t" + nfVec(vLorentz, 3) + "\n"
             + "vExpect:\t"  + nfVec(vExpect, 3) + "\n" );
  
  
  // Test the Display Transform: With space & time enabled, it should match the regular lorentz transform...
  
  Relativity.TOGGLE_SPATIAL_TRANSFORM = true;
  Relativity.TOGGLE_TEMPORAL_TRANSFORM = true;
  
  Vector3f vDisplay = Relativity.displayTransform(vel, v1);
  
  tester.ok( getDistance(vDisplay, vLorentz) < 0.01,
            "Display transform (with Space & Time enabled) should match Lorentz transform" );

  
  // Test the Inverse Transform: It should reverse the regular lorentz transform
  
  Vector3f vInverse = Relativity.inverseLorentzTransform(vel, vLorentz);
  
  tester.ok( getDistance(vInverse, v1) < 0.01,
             "Inverse Transform of Lorentz Transformed vector should give back the original vector",
               "v1: " + nfVec(v1, 3) + "\n"
             + "vLorentz: " + nfVec(vLorentz, 3) + "\n"
             + "vInverse: " + nfVec(vInverse, 3) + "\n" );
  

  // Test the Display Transform: With only time component enabled

  Relativity.TOGGLE_SPATIAL_TRANSFORM = false;
  Relativity.TOGGLE_TEMPORAL_TRANSFORM = true;
  
  Vector3f vDisplayTemporal = Relativity.displayTransform(vel, v1);
  Vector3f vInverseDisplayTemporal = Relativity.inverseDisplayTransform(vel, vDisplayTemporal);
  
  tester.ok( getDistance(vInverseDisplayTemporal, v1) < 0.01,
             "Inverse Display Transform of Display Transformed vector should give back the original vector",
               "v1: " + nfVec(v1, 3) + "\n"
             + "vDisplay: " + nfVec(vDisplayTemporal, 3) + "\n"
             + "vInverseDisplay: " + nfVec(vInverseDisplayTemporal, 3) + "\n" );
  
  
  print(tester.getResultSummary());
}

class Tester {

  int numTests;
  String unitName;
  Collection testResults = new ArrayList();
  
  boolean verbose;
  
  // Create a new Tester, given a name for this unit and the number of tests we expect
  Tester(String unitName, int numTests) {
    this.unitName = unitName;
    this.numTests = numTests;
  }

  // Register the result of a declarative test - which is "ok" if true -
  // along with a descriptive name for the test.
  // The "details" string will be printed in the unit summary if the test fails,
  // useful for including debugging information which might hint as to what went wrong.
  void ok(boolean result, String desc, String details) {

    TestResult testResult = new TestResult(result, desc, details);

    testResults.add(testResult);
  }
  
  // Register the result of a test, associating it with a descriptive name.
  // Also see the version of ok() which allows debugging details.
  void ok (boolean result, String desc) {
    this.ok(result, desc, "");
  }
  
  // Returns a string summarizing the result of each test within the unit,
  // and the unit as a whole.
  String getResultSummary() {
    
    StringBuffer sb = new StringBuffer();
    
    Iterator iter = this.testResults.iterator();
    while (iter.hasNext()) {

      TestResult testResult = (TestResult) iter.next();
      
      // A line with the status of each test and a description of what was tested
      sb.append( ( testResult.result ? "Ok:\t" : "Fail:\t" ) + testResult.desc + "\n" );

      // If the test failed (or verbose is enabled), include the test's debugging details
      if (testResult.result == false || this.verbose) {
        sb.append( testResult.details );
      }
    }
    
    // A line for the overall results of this unit. Did all tests pass?
    sb.append(
      this.allPassed()
      ? "Results: All Tests Passed\n"
      : "Results: Failed " + this.getFailCount() + " of " + this.numTests + " tests\n"
    );
    
    // Warn if actual number of tests didn't match what we expected to find
    if (this.numTests != testResults.size()) {
      sb.append("WARNING: Expected " + this.numTests +
                " tests, but found " + testResults.size() + "\n");
    }
    
    return sb.toString();
  }
  
  // Return true only if all tests passed
  boolean allPassed() {
    return (this.getFailCount() == 0);
  }
  
  // Return the count of how many tests failed
  int getFailCount() {
    
    int count = 0;

    for (Iterator iter = this.testResults.iterator(); iter.hasNext(); ) {
      TestResult tr = (TestResult) iter.next();
      if (!tr.result) {
        count++;
      }
    }
    return count;
  }
  
  // Subclass for storing the boolean result of a test condition,
  // along with a short description of what the condition tested,
  // and any details useful for debugging failed tests.
  class TestResult {
    
    // The test condition result ("true" if passed, "false" if failed)
    boolean result;
    String desc;
    String details;
    
    TestResult(boolean result, String desc, String details) {
      this.result = result;
      this.desc = desc;
      this.details = details;
    }
    
    TestResult(boolean result, String desc) {
      this(result, desc, "");
    }
  }
}

