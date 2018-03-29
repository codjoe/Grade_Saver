import de.voidplus.leapmotion.*;
import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import processing.sound.*;
SoundFile file,file1;
SoundFile backgroundMusic;
SoundFile startMusic;
ArrayList<Vector> fingerPositions = new ArrayList<Vector>();

Box2DProcessing e; // this is our world

ArrayList<Books> theFruits;
ArrayList<Splash> theSplashes;

ArrayList<Bomb> theBomb;
ArrayList<BombSplash> theBombSplashes;
int score;
int difficulty=1;
int level = 20;
int lives;
color bg= #957777;
float G=0.4;
float d;
SampleListener listener;
Controller controller;

PImage backgroundImage;

int swipeR, swipeG, swipeB;

void setup()
{
  
    // Load a soundfile from the /data folder of the sketch and play it back
  file = new SoundFile(this, "fruit.mp3");
  file1 = new SoundFile(this, "ouch.mp3");
    startMusic = new SoundFile(this, "NinjaBook.mp3");
  startMusic.play();

  backgroundMusic = new SoundFile(this, "BackgroundNinja.mp3");
  backgroundMusic.play();
  backgroundMusic.loop();

  
  
  
  size(displayWidth, displayHeight, OPENGL);
  textAlign(CENTER,CENTER);
  theFruits = new ArrayList<Books>();

  theSplashes = new ArrayList<Splash>();
  
  theBomb = new ArrayList<Bomb>();

  theBombSplashes = new ArrayList<BombSplash>();

  // this sets up the box2d physics engine to deal with us
  e = new Box2DProcessing(this);
  e.createWorld();
  // To change the gravity, and how many random book are being thrown, play with the numbers below
  //.....................................................................................
  e.setGravity(3, -9);
  d= random(50, 100);
  //......................................................................................
  // Create a sample listener and assign it to a controller to receive events
  listener = listener = new SampleListener();
  controller = new Controller(listener);

  backgroundImage = loadImage("Background.png");

  swipeR = int(random(400, 510));
  swipeG = int(random(400, 510));
  swipeB = int(random(400, 510));
  
    score=0;
  lives=1000;
}

void draw()
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

  //background(bg);
  textSize(44);
  fill(#FF0000);
  text("score: "+score, 100, 120);
  //text("strength: "+lives, 20, 200);


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
  
  ArrayList<BombSplash> splashesToRemoveBomb = new ArrayList<BombSplash>();
  
  for (Splash splash: theSplashes)
  {
    
   
    splash.display();

    // remove splashes if their counter > 255
    if (splash.counter > 255) splashesToRemove.add(splash);
    
  }
  
  //bomb
    for (BombSplash bombsplash: theBombSplashes)
  {
    
   
    bombsplash.display();

    // remove splashes if their counter > 255
    if (bombsplash.counter > 255) splashesToRemoveBomb.add(bombsplash);
    
  }

  for (Splash splash: splashesToRemove) theSplashes.remove(splash);
  for (BombSplash bombsplash: splashesToRemoveBomb) theBombSplashes.remove(bombsplash);//bomb
  
  for (Books fruit: theFruits)
  {
    
    fruit.display();
  }
  //bomb
  
    for (Bomb bomb: theBomb)
  {
    
    bomb.display();
  }

  

  // remove the fruits that are off the screen

  ArrayList<Books> fruitsToRemove = new ArrayList<Books>(); 
  for (Books fruit: theFruits) {
    Vec2 position = e.coordWorldToPixels(fruit.body.getPosition());
    if (position.y > height*2 && fruit.body.getLinearVelocity().y < 0) {
      fruitsToRemove.add(fruit);
    }
  }
  
  
  
  // remove the bomb that are off the screen

  ArrayList<Bomb> bombsToRemove = new ArrayList<Bomb>(); 
  for (Bomb bomb: theBomb) {
    Vec2 position = e.coordWorldToPixels(bomb.body.getPosition());
    if (position.y > height*2 && bomb.body.getLinearVelocity().y < 0) {
      bombsToRemove.add(bomb);
    }
  }

  for (Books fruitToRemove: fruitsToRemove) {
    fruitToRemove.killBody();
    theFruits.remove(fruitToRemove); 
  }
  fruitsToRemove.clear();
  //bomb

    for (Bomb bombToRemove: bombsToRemove) {
    bombToRemove.killBody();
    theBomb.remove(bombToRemove); 
  }
  bombsToRemove.clear();

  // check if the swipe intersects any of the fruits.. if so, remove them and add splash
  for (Books fruit: theFruits) {
    if ((listener.hasHands || (!listener.connected)) && fingerPositions.size() > 0) {

      Vector fingerPos = fingerPositions.get(0);
      Vec2 fruitPosition = e.coordWorldToPixels(fruit.body.getPosition());      // center of fruit

      float fingerPosX = (float)(fingerPos.getX() + 200) / 400 * width;
      float fingerPosY = height - (float)(fingerPos.getY()) / 600 * height;
      
      float spriteSize = fruit.fruitSprite.width;    // width and height are same

      if (fingerPosX > fruitPosition.x - spriteSize/2.0 && fingerPosX < fruitPosition.x + spriteSize/2.0 && fingerPosY > fruitPosition.y - spriteSize/2.0 && fingerPosY < fruitPosition.y + spriteSize/2.0) {
        // swiped!
        println("SWIPED!");
        //...............................................................................
        // To change the score of the books swipe, change score++ to score+=2 or score+=3 so and for.
        if (score  < 10000)score++; // Add +1 everytime a book is swiped
//........................................................................................
        // This is where the sound play in a loop when a book get slice
         file.play();
        fruitsToRemove.add(fruit);

         
  
    }
  }
  }
  //Game over
          if (score < 0){
          
            
          fill(#FF0000); 
          text("GAME OVER", width/2, height/3 -100);
          text("CLICK TO RESTART", width/2, height/3 -50);
          if(mousePressed){
            score=0;
          }
        }
  //bomb
    // check if the swipe intersects any of the bomb.. if so, remove them and add splash
  for (Bomb bomb: theBomb) {
    if ((listener.hasHands || (!listener.connected)) && fingerPositions.size() > 0) {

      Vector fingerPos = fingerPositions.get(0);
      Vec2 fruitPosition = e.coordWorldToPixels(bomb.body.getPosition());      // center of fruit

      float fingerPosX = (float)(fingerPos.getX() + 200) / 400 * width;
      float fingerPosY = height - (float)(fingerPos.getY()) / 600 * height;
      
      float spriteSize = bomb.bombSprite.width;    // width and height are same

      if (fingerPosX > fruitPosition.x - spriteSize/2.0 && fingerPosX < fruitPosition.x + spriteSize/2.0 && fingerPosY > fruitPosition.y - spriteSize/2.0 && fingerPosY < fruitPosition.y + spriteSize/2.0) {
        // swiped!
        println("SWIPED!");
        //..............................................................................
        // To change the score of the bomb swipe, change score-- to score-= 2 or score-=3 so and for
        if (score  < 10000)score--; // Substract -1 everytime a book is swiped
        //...............................................................................
        // This is where the sound play in a loop when a book get slice
         file1.play();
        bombsToRemove.add(bomb);

         
  
    }
  }
  }

  for (Books fruitToRemove: fruitsToRemove) {
    Vec2 fruitPosition = e.coordWorldToPixels(fruitToRemove.body.getPosition());

    // add splash
    Splash splash = new Splash(fruitToRemove.fruitName(), fruitPosition);
    theSplashes.add(splash);

    fruitToRemove.killBody();
    theFruits.remove(fruitToRemove);
  }
  
  //bomb
    for (Bomb bombToRemove: bombsToRemove) {
    Vec2 fruitPosition = e.coordWorldToPixels(bombToRemove.body.getPosition());

    // add splash
    BombSplash bombsplash = new BombSplash(bombToRemove.bombName(), fruitPosition);
    theBombSplashes.add(bombsplash);

    bombToRemove.killBody();
    theBomb.remove(bombToRemove);
  }


  // new level
  if (theFruits.size() == 0) {
    // increment the level... add fruits
    level++;
    int numFruits = (int)random(0, 20);
    for (int i = 0; i < numFruits; i++) {
      int randomX = int(random(0, width));
      int impulseX = int(random(0, width));
      if (randomX > width/2) impulseX *= -1; 

      Books p = new Books(randomX, height + 80); 
      theFruits.add(p);

      p.body.applyAngularImpulse(0.5);
      p.body.applyLinearImpulse(new Vec2(impulseX, random(height * 2, height * 3)), e.getBodyPixelCoord(p.body),true);
    }
  }
  
    // new level bomb
  if (theBomb.size() == 0) {
    // increment the level... add fruits
    level++;
    int numBomb = (int)random(0, 20);
    for (int i = 0; i < numBomb; i++) {
      int randomX = int(random(0, width));
      int impulseX = int(random(0, width));
      if (randomX > width/2) impulseX *= -1; 

      Bomb p = new Bomb(randomX, height + 80); 
      theBomb.add(p);

      p.body.applyAngularImpulse(0.5);
      p.body.applyLinearImpulse(new Vec2(impulseX, random(height * 2, height * 3)), e.getBodyPixelCoord(p.body),true);
    }
  }
 
  }