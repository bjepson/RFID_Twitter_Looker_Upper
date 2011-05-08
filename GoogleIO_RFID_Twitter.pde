import processing.serial.*;

PFont font;
int seeking = 0;
int warmedUp = 0;
Serial mySerial;       
String currentName = null;
float startTime;

void setup() 
{

  // Open the serial port.
  println(Serial.list());
  mySerial = new Serial(this, Serial.list()[0], 9600);

  // Set a start timer--we'll wait for Arduino to boot before talking to it.
  startTime = millis();

  // Set up the display
  size(640, 480);
  smooth();

  // Set the font
  font = loadFont("CourierNew36.vlw");
  textFont(font, 36);
} 

// If you press a key, ask the Arduino to seek a tag.
//
void keyReleased() {

  // Wait until we're warmed up.
  //
  if (warmedUp == 1) {

    mySerial.clear();     // clear the buffer
    mySerial.write('s');  // ask Arduino to seek
    delay(250);           // wait

    String inBuffer = getString();   
    if (inBuffer.equals("READY")) {
      seeking = 1;
    }
  }
}


void draw() 
{

  // Standard messages
  //
  String[] pressAnyKey = {
    "Press", "Any", "Key"
  };  

  String[] readingTag = {
    "Reading", "Your", "Tag"
  };  

  String[] waitingForTag = {
    "Waiting", "For", "Tag"
  };  
  String[] hello = {
    "Hello", "There,", "@" + currentName
  };

  if (millis() > startTime + 3000) {
    warmedUp = 1;
  }

  // Check to see what state we're in.
  switch(seeking) {
  case 0:
    if (warmedUp == 1) {  // Ready to start.
      background(200);
      drawMsg(pressAnyKey, 15, 30);
    }
    break;
  case 1:
    background(180); 
    drawMsg(waitingForTag, 150, 150);
    if (mySerial.available () > 0) { // Check to see if we got anything from Arduino

      String response = getString();

      String[] splitResponse = split(response, "/");

      // Debug stuff
      //println("[" + splitResponse[0] + "]");
      //for (int i = 0; i < splitResponse[0].length(); i++) {
      //  println("[" + splitResponse[0].charAt(i) + "]");
      //}

      if (splitResponse[0].equals("Utwitter.com")) {
        currentName = splitResponse[1];
        seeking = 2; // Move on to the next state (querying Twitter)
      } 
      else {
        currentName = ""; // didn't get a Twitter URL. Try with another tag.
      }
    }
    break;
  case 2:
    background(160);
    drawMsg(hello, 240, 50); // Say hello to the user
    int d = day();   
    int m = month(); 
    int y = year();  
    String date = y + "-" + nf(m, 2) + "-" + nf(d, 2);
    println(date);

    XMLElement xml = new XMLElement(this, "http://search.twitter.com/search.atom?q=from%3A" + currentName + "&since=" + date);
    println("Child count: " + xml.getChildCount());
    int recentCount = 0;
    for (int i = 0; i < xml.getChildCount(); i++) {
      if (xml.getChild(i).getName().equals("entry")) {
        recentCount++;
      }
    }
    println(recentCount);
    if (recentCount > 0) {
      mySerial.write("+"); // Good for you!
    } 
    else {
      mySerial.write("-"); // Get tweeting!
    }
    seeking = 0;
    currentName = "";
    startTime = millis();
    warmedUp = 0;
  }
}

// Read a string from the serial port
String getString() {
  String inBuffer = "";   
  while (mySerial.available () > 0) {
    inBuffer += mySerial.readString();
    delay(100);
  }
  return inBuffer;
}

// Draw a message all pretty and like.
void drawMsg(String[] msg, int x, int y) {

  int opacity = 100;

  for (int i = 0; i < msg.length; i++) {
    fill(0, 102, 153, opacity);
    text(msg[i], x, y + 36 * i); 
    opacity += 25;
  }
} 

