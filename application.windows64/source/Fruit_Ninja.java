import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import de.voidplus.leapmotion.*; 
import shiffman.box2d.*; 
import org.jbox2d.collision.shapes.*; 
import org.jbox2d.common.*; 
import org.jbox2d.dynamics.*; 
import com.leapmotion.leap.*; 
import com.leapmotion.leap.Hand; 
import com.leapmotion.leap.Finger; 

import com.leapmotion.leap.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Fruit_Ninja extends PApplet {











ArrayList<Vector> fingerPositions = new ArrayList<Vector>();

Box2DProcessing e; // this is our world

ArrayList<Fruit> theFruits;
ArrayList<Splash> theSplashes;

int level = 20;

SampleListener listener;
Controller controller;

PImage backgroundImage;

int swipeR, swipeG, swipeB;

public void setup()
{
  

  theFruits = new ArrayList<Fruit>();
  theSplashes = new ArrayList<Splash>();

  // this sets up the box2d physics engine to deal with us
  e = new Box2DProcessing(this);
  e.createWorld();
  e.setGravity(3, -20);

  // Create a sample listener and assign it to a controller to receive events
  listener = listener = new SampleListener();
  controller = new Controller(listener);

  backgroundImage = loadImage("Background.png");

  swipeR = PApplet.parseInt(random(400, 510));
  swipeG = PApplet.parseInt(random(400, 510));
  swipeB = PApplet.parseInt(random(400, 510));
}

public void draw()
{ 
  swipeR += random(-20, 20);
  swipeG += random(-20, 20);
  swipeB += random(-20, 20);
  swipeR = constrain(swipeR, 400, 510);
  swipeG = constrain(swipeG, 400, 510);
  swipeB = constrain(swipeB, 400, 510);

  background(0);
  tint(255);
  image(backgroundImage, 0, 0, width, height);

  fill(255);
  stroke(swipeR, swipeG, swipeB);
  strokeJoin(ROUND);
  strokeCap(ROUND);

  if ((listener.lastPos != null && listener.connected) || !listener.connected) {
    // remove the last position if fingerPositions has more than 20 positions
    if (fingerPositions.size() > 20) fingerPositions.remove(fingerPositions.size() - 1);

    Vector lastPos;

    if (listener.connected) {
      // add the new position at index 0
      lastPos = listener.lastPos;
    } 
    else {
      lastPos = new Vector(mouseX / (float)(width) * 400 - 200, (height - mouseY) / (float)(height) * 600, 0);
    }

    fingerPositions.add(0, lastPos);

    for (int i = 0; i < fingerPositions.size() - 1; i++) {
      Vector fingerPos1 = fingerPositions.get(i);
      Vector fingerPos2 = fingerPositions.get(i+1);

      float normalizedX1 = (float)(fingerPos1.getX() + 200) / 400 * width;
      float normalizedY1 = height - (float)(fingerPos1.getY()) / 600 * height;
      float normalizedX2 = (float)(fingerPos2.getX() + 200) / 400 * width;
      float normalizedY2 = height - (float)(fingerPos2.getY()) / 600 * height;

      //ellipse(normalizedX, normalizedY, fingerPositions.size() - i, fingerPositions.size() - i);

      strokeWeight(fingerPositions.size() - i);
      line(normalizedX1, normalizedY1, normalizedX2, normalizedY2);
    }
  }

  e.step(); // advances the physics engine one frame

  ArrayList<Splash> splashesToRemove = new ArrayList<Splash>();
  for (Splash splash: theSplashes)
  {
    splash.display();

    // remove splashes if their counter > 255
    if (splash.counter > 255) splashesToRemove.add(splash);
  }

  for (Splash splash: splashesToRemove) theSplashes.remove(splash);

  for (Fruit fruit: theFruits)
  {
    fruit.display();
  }


  // remove the fruits that are off the screen

  ArrayList<Fruit> fruitsToRemove = new ArrayList<Fruit>(); 
  for (Fruit fruit: theFruits) {
    Vec2 position = e.coordWorldToPixels(fruit.body.getPosition());
    if (position.y > height*2 && fruit.body.getLinearVelocity().y < 0) {
      fruitsToRemove.add(fruit);
    }
  }

  for (Fruit fruitToRemove: fruitsToRemove) {
    fruitToRemove.killBody();
    theFruits.remove(fruitToRemove);
  }
  fruitsToRemove.clear();

  // check if the swipe intersects any of the fruits.. if so, remove them and add splash
  for (Fruit fruit: theFruits) {
    if ((listener.hasHands || (!listener.connected)) && fingerPositions.size() > 0) {

      Vector fingerPos = fingerPositions.get(0);
      Vec2 fruitPosition = e.coordWorldToPixels(fruit.body.getPosition());      // center of fruit

      float fingerPosX = (float)(fingerPos.getX() + 200) / 400 * width;
      float fingerPosY = height - (float)(fingerPos.getY()) / 600 * height;
      
      float spriteSize = fruit.fruitSprite.width;    // width and height are same

      if (fingerPosX > fruitPosition.x - spriteSize/2.0f && fingerPosX < fruitPosition.x + spriteSize/2.0f && fingerPosY > fruitPosition.y - spriteSize/2.0f && fingerPosY < fruitPosition.y + spriteSize/2.0f) {
        // swiped!
        println("SWIPED!");
        fruitsToRemove.add(fruit);
      }
    }
  }

  for (Fruit fruitToRemove: fruitsToRemove) {
    Vec2 fruitPosition = e.coordWorldToPixels(fruitToRemove.body.getPosition());

    // add splash
    Splash splash = new Splash(fruitToRemove.fruitName(), fruitPosition);
    theSplashes.add(splash);

    fruitToRemove.killBody();
    theFruits.remove(fruitToRemove);
  }


  // new level
  if (theFruits.size() == 0) {
    // increment the level... add fruits
    level++;
    int numFruits = (int)random(2, 15);
    for (int i = 0; i < numFruits; i++) {
      int randomX = PApplet.parseInt(random(0, width));
      int impulseX = PApplet.parseInt(random(0, width));
      if (randomX > width/2) impulseX *= -1; 

      Fruit p = new Fruit(randomX, height + 80); 
      theFruits.add(p);

      p.body.applyAngularImpulse(0.5f);
      p.body.applyLinearImpulse(new Vec2(impulseX, random(height * 2, height * 3)), e.getBodyPixelCoord(p.body),true);
    }
  }
}
class Fruit
{
  Body body;
  BodyDef bd;
  FixtureDef fd;
  PImage fruitSprite;

  int type;

  public String fruitName()
  {
    if (type == 0) {
     return "Apple"; 
    } else if (type == 1) {
     return "Apricot"; 
    } else if (type == 2) {
     return "Banana"; 
    } else if (type == 3) {
     return "Orange"; 
    } else if (type == 4) {
     return "Peach"; 
    } else if (type == 5) {
     return "Pear"; 
    } else if (type == 6) {
     return "Strawberry"; 
    }
    return "Apple";
  }

  Fruit(float x, float y)
  {
    type = (int)(random(0, 7));
    String spriteName = fruitName();
    
    fruitSprite = loadImage(spriteName + ".png");

    // make me a new body
    bd = new BodyDef();
    bd.type = BodyType.DYNAMIC; // it's gonna move
    bd.position.set(e.coordPixelsToWorld(x, y)); // this is where it starts
    body = e.createBody(bd); // registers it with the physics engine

    // this describes the shape of the thing
    CircleShape ps = new CircleShape();
    ps.m_radius = e.scalarPixelsToWorld(fruitSprite.width/2);
    // this makes the fixture
    fd = new FixtureDef();
    fd.shape = ps; // assigns the shape to the fixture

    // some parameters
    fd.density = 1.f;
    fd.friction = 0.3f;
    fd.restitution = 1.f;
    fd.isSensor = true;

    body.createFixture(fd);
  }

  public void display()
  {
    Vec2 pos = e.getBodyPixelCoord(body); // find out where it is
    float a = body.getAngle();
    
    rectMode(CENTER);
    pushMatrix();
    translate(pos.x,pos.y);
    rotate(-a/180*PI);
    translate(-fruitSprite.width/2.0f, -fruitSprite.height/2.0f);
    
    tint(255);
    image(fruitSprite, 0, 0, fruitSprite.width, fruitSprite.height);
        
    popMatrix();
  }

  public void killBody()
  {
    e.destroyBody(body);
  }
}



class SampleListener extends Listener {

  Vector lastPos;
  boolean hasHands;
  boolean connected = false;

  public void onInit(Controller controller) {
    println("Initialized");
  }

  public void onConnect(Controller controller) {
    println("Connected");
    connected = true;
  }

  public void onDisconnect(Controller controller) {
    println("Disconnected");
    connected = false;
  }

  public void onFrame(Controller controller) {
    // Get the most recent frame and report some basic information

    Frame frame = controller.frame();
    HandList hands = frame.hands();
    long numHands = hands.count();
    
    System.out.println("Frame id: " + frame.id()
      + ", timestamp: " + frame.timestamp()
      + ", hands: " + numHands);

    if (numHands == 0) {
      hasHands = false;
    } 
    else {
      hasHands = true;
      // Get the first hand
     Hand hand = hands.get(0);
      // Check if the hand has any fingers
      FingerList fingers = hand.fingers();
      long numFingers = fingers.count();
      if (numFingers >= 1) {
        // Calculate the hand's average finger tip position
        Vector pos = new Vector(0, 0, 0);
        for (int i = 0; i < numFingers; ++i) {
          Finger finger = fingers.get(i);
          Vector tip = finger.tipPosition();
          pos.setX(pos.getX() + tip.getX());
          pos.setY(pos.getY() + tip.getY());
          pos.setZ(pos.getZ() + tip.getZ());
        }
        pos = new Vector(pos.getX()/numFingers, pos.getY()/numFingers, pos.getZ()/numFingers);
        //        println("Hand has " + numFingers + " fingers with average tip position"
        //          + " (" + pos.getX() + ", " + pos.getY() + ", " + pos.getZ() + ")");

        lastPos = pos;
      }
    }
    
  }
}
class Splash {
  
 int counter = 0;
 PImage splashImage;
 Vec2 pos;
 
 Splash(String fruitName, Vec2 position) {
   splashImage = loadImage(fruitName + "_Splash.png");
   pos = position;
   pos.x -= 120;
   pos.y -= 120;
 }
 
 public void display()
  {
    counter++;
    tint(255.0f, 255-counter);
    image(splashImage, pos.x, pos.y, splashImage.width, splashImage.height);
  }
}
  public void settings() {  size(displayWidth, displayHeight, OPENGL); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--stop-color=#cccccc", "Fruit_Ninja" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
