import processing.serial.*;

import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;

Capture video;
Serial serial;

OpenCV cvFlip; // just to flip the image  
OpenCV cv;     // for face detection

Rectangle[] faces;

int cvWidth; 
int cvHeight;
int cvDivider = 4; // the higher the smaller the cv resolution
int pixelBracket = 10;

PImage detectionImg;

float faceXFactor;     // value between 0.0 - 1.0
float lastFaceXFactor = 0.5; // for smoothing

float faceYFactor;     // value between 0.0 - 1.0
float lastFaceYFactor = 0.5; // for smoothing

float faceSizeFactor;  // value between 0.0 - 1.0
float lastFaceSizeFactor = 0.5; // for smoothing

float smoothFactor = 0.3; // 30% of the current, 70% of the last

boolean showDetection = true;

void setup() {
  size(1280, 720);
  frameRate(30);

  video = new Capture(this, width, height);
  video.start();  

  serial = new Serial(this, "COM3", 9600); 

  // we use one OpenCV object for flipping the video on full resolution
  cvFlip = new OpenCV( this, video.width, video.height); 
  cvFlip.useColor();

  cvWidth = video.width/cvDivider;
  cvHeight = video.height/cvDivider;

  // we use another OpenCV object for face tracking
  // we do this on a greyscale image with a smaller resolution
  // to make it less processor intensive
  cv = new OpenCV(this, cvWidth, cvHeight);

  detectionImg = createImage(cvWidth, cvHeight, RGB);

  // Load HAAR cascade to detect a feature. 
  // We can use the constants from the library or you can load some alternative (see data folder 
  // in this sketch.
  // OpenCV.CASCADE_FRONTALFACE detects most faces, however the other ones are more precise. 
  // Other things (nose, eyes, mouths) don't work so stable. 

  cv.loadCascade(OpenCV.CASCADE_FRONTALFACE); // detect faces
  //cv.loadCascade("haarcascade_frontalface_alt.xml");
  //cv.loadCascade(OpenCV.CASCADE_EYE); // or use CASCADE_EYE, CASCADE_NOSE
  faces = cv.detect();

  // setup properties
  noFill();
  strokeWeight(3);
  textSize(32);
  textAlign(LEFT, TOP);
}

void draw() {

  // read the video frame and detect the faces
  if (video.available()) {
    video.read();

    cvFlip.loadImage(video);
    cvFlip.flip(OpenCV.HORIZONTAL); 

    // copy and scale the cvFlip image to a PImage
    detectionImg.copy(cvFlip.getOutput(), 0, 0, cvFlip.width, cvFlip.height, 0, 0, cv.width, cv.height);

    // load the PImage into the cv object for detection
    cv.loadImage(detectionImg);

    // detect faces (or other cascade elements
    faces = cv.detect();
  }

  image( cvFlip.getOutput(), 0, 0 ); // show the flipped color image



  // draw rectangle around the face in the full color image
  stroke(255, 0, 0);

  // scaled up version
  // the biggest face has always highest index
  // if we only would like to find the biggest face (so probaly most in front of the cam)
  // we can do this with faces[faces.length-1] and a check to see if faces.length > 0
  for (int i = 0; i < faces.length; i++) {

    // scale it up with the cvDivider
    int faceX    = faces[i].x * cvDivider;
    int faceY    = faces[i].y * cvDivider;
    int faceSize = faces[i].width * cvDivider; // it's always a square so width/height are equal

    int halfFaceSize   = (faceSize/2);
    int faceXmiddle = faceX + halfFaceSize;
    int faceYmiddle = faceY + halfFaceSize;

    // relative position on screen between 0.0 - 1.0 (0 and 100%)
    faceXFactor = map(faceXmiddle, 0 + halfFaceSize, width - halfFaceSize, 0.0, 1.0); 
    faceYFactor = map(faceYmiddle, 0 + halfFaceSize, height - halfFaceSize, 0.0, 1.0); 

    // minimal faceSize of 20 is a guess, compare with height, since that is shorter
    // -80 based on trail for this resolution
    faceSizeFactor = map(faceSize, 20, height - 80, 0.0, 1.0); 
    faceSizeFactor = constrain(faceSizeFactor, 0.0, 1.0);
    //println(height+" "+faceSize);

    if (showDetection) {
      rect(faceX, faceY, faceSize, faceSize); // show rectangle
      ellipse(faceXmiddle, faceYmiddle, 10, 10); // draw center
      text(i, faceX+4, faceY); // show number
      
    
    if (faceXmiddle < width/2 - pixelBracket) {
        println("LEFT");
        serial.write('a');
      }

      if (faceXmiddle > width/2 + pixelBracket) {
        println("RIGHT");
        serial.write('b');
      }

      if (faceYmiddle < height/2 - pixelBracket) {
        println("UP");
        serial.write('c');
      }

      if (faceYmiddle > height/2 + pixelBracket) {
        println("DOWN");
        serial.write('d');
      }

      if ((faceXmiddle >= width/2 - pixelBracket) && (faceXmiddle <= width/2 + pixelBracket) && (faceYmiddle >= height/2 - pixelBracket) && (faceYmiddle <= height/2 + pixelBracket)) {
        println("GOTCHA");
        serial.write('e');
      }
      
      
    }
  }

  // smooth
  faceXFactor = (smoothFactor * faceXFactor) + ((1-smoothFactor) * lastFaceXFactor); 
  lastFaceXFactor = faceXFactor;

  faceYFactor = (smoothFactor * faceYFactor) + ((1-smoothFactor) * lastFaceYFactor); 
  lastFaceYFactor = faceYFactor;

  faceSizeFactor = (smoothFactor * faceSizeFactor) + ((1-smoothFactor) * lastFaceSizeFactor); 
  lastFaceSizeFactor = faceSizeFactor;

  if (showDetection) {
    // draw a triangle as an arrow on the bottom of the screen for the X
    triangle(  (faceXFactor * width)-10, (height - 10), 
    (faceXFactor * width), (height - 20), 
    (faceXFactor * width)+10, (height - 10));

    // draw a triangle as an arrow on the right of the screen for the Y
    triangle(  width-10, (faceYFactor * height) - 10, 
    width-20, (faceYFactor * height), 
    width-10, (faceYFactor * height) + 10);

    // draw an ellipse on the top to represent the size
    ellipse((faceSizeFactor * width), 10, 10, 10);
    
    
    
    
  }
}

