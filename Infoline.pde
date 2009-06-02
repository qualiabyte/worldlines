// Infoline
// tflorez

class Infoline {

  Infoline() {
    text = "";
  }
  
  Infoline( String text ) {
    this.text = text;
  }
  
  void setText( String text ) {
    this.text = text;
  }
  
  String toString() {
    return text;
  }
  
  String text;
}
