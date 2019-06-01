import java.util.ArrayList;
import processing.sound.*;
import java.io.File;

boolean selectionScreen = false;

//the selected character index
int selection = 0;

//the currently displayed dialogue line
int dialogueIndex = 0;

//index of currently displayed letter in dialogue line
int letterIndex = 0;

//write out a new letter every n frames (default: 4)
int dialogueSpeed = 1;

//play the speech sound effect every nth letter +- speedvariance
int soundfxSpeed = 10;
int soundfxSpeedVariance = 3;
int soundfxCurrentVariance = 0;
int soundfxTimer = 0;

//the "player" for the dialogue soundfx
SoundFile dialogueSfx;

//is text currently being written out
boolean writeText = false;

//cursor position
PVector cursorPosition;

//load the sprites
PImage cursorSprite;
PImage dialogueboxSprite;

//make the character array
Character[] characters = new Character[3];

void setup() {
  size(600, 600);

  //disable bilinear image filtering
  noSmooth();  

  //load sprites
  cursorSprite = loadImage("graphics/ui/cursor.png");
  dialogueboxSprite = loadImage("graphics/ui/dialoguebox.png");

  //create characters
  characters[0] = new Character("Orc", 
    loadImage("graphics/characters/orc.png"), 
    getDialogue("dialogue/orcdialogue.txt"), 
    getDialogueSounds("orc")
    );

  characters[1] = new Character("Wizard", 
    loadImage("graphics/characters/wizard.png"), 
    getDialogue("dialogue/wizarddialogue.txt"), 
    getDialogueSounds("wizard")
    );

  characters[2] = new Character("Elf", 
    loadImage("graphics/characters/elf.png"), 
    getDialogue("dialogue/elfdialogue.txt"), 
    getDialogueSounds("elf")
    );

  //set initial cursor position
  updateCursorPosition();

  characterSelectionScreen();
}

void keyReleased() {  
  //increase or decrease the selection index if the character selection screen is showing
  if (selectionScreen) {
    if (keyCode == RIGHT || keyCode == 'd') {
      //right arrow key or "d" pressed
      selection = ++selection%characters.length;
      refreshCursor();
    } else if (keyCode == LEFT || keyCode == 'a') {
      //left arrow key or "a" pressed
      selection = selection-1 < 0 ? characters.length-1 : --selection;
      refreshCursor();
    } else if (keyCode == ENTER) {
      dialogueScreen();
    }
  } else {
    //skip dialogue with enter key, return to selection screen with backspace key
    if (keyCode == ENTER) {
      if (writeText) {
        skipDialogueLine();
      } else {
        if (dialogueIndex < characters[selection].dialogue.length-1) {
          dialogueIndex++;
          startDialogueLine();
        } else {
          characterSelectionScreen();
        }
      }
    } else if (keyCode == BACKSPACE) {
      characterSelectionScreen();
    }
  }
}

void refreshCursor() {
  //clear the previous cursor
  noStroke();
  fill(0);
  rectMode(CORNER);
  rect(cursorPosition.x, cursorPosition.y, 16, 16);

  //update cursor position
  updateCursorPosition();

  //show cursor
  image(cursorSprite, cursorPosition.x, cursorPosition.y, 16, 16);
}

void updateCursorPosition() {
  //update the position of the cursor
  cursorPosition = new PVector((selection*100) + ((selection+1)*((width-(100*characters.length))/(characters.length+1))) + 42, height/2 + 80);
}

void characterSelectionScreen() {
  //clear screen
  background(0);

  selectionScreen = true;

  //show each character, equally spaced on screen
  for (int i = 0; i < characters.length; i++) {
    //sprite size is 100 pixels
    characters[i].selected = false;
    characters[i].position = new PVector((i*100) + ((i+1)*((width-(100*characters.length))/(characters.length+1))), height/2 - 50);
    characters[i].show();
  }

  //show the cursor
  refreshCursor();
}

void dialogueScreen() {
  //clear screen
  background(0);

  selectionScreen = false;

  dialogueIndex = 0;

  //show character
  characters[selection].selected = true;
  characters[selection].position = new PVector(width/2 - 100, height/2 - 200);
  characters[selection].show();

  //show character name
  fill(255);
  textSize(24);
  text(characters[selection].name, 40, height/2 + 110 - textAscent());

  //display dialogue text
  startDialogueLine();
}

void startDialogueLine() {
  image(dialogueboxSprite, 25, height/2 + 100, width-50, (width-50)/4);
  letterIndex = 0;
  writeText = true;
}

void skipDialogueLine() {
  letterIndex = characters[selection].dialogue[dialogueIndex].length()-1;
}

//refactor plain text into bits that fit the dialogue box
String[] getDialogue(String filename) {
  String[] dialogue = loadStrings(filename);
  ArrayList<String> fixedDialogue = new ArrayList<String>();

  //each string in the array is one dialogue box.
  //check if width of string exceeds dialogue box width and if necessary, insert linebreaks between words.
  for (String line : dialogue) {
    textSize(18);
    if (textWidth(line) > width-130) {
      //if text overall exceeds dialogue box width, fill up each line with words until limit is reached

      //break line up into words
      String[] dialogueWords = line.split(" ");
      String tempLine = "";

      //keep track of the line count
      int lineCount = 0;

      //if a word exceeds the horizontal dialogue box boundaries, make a new line. If it exceeds the vertical boundaries, make a new dialogue bit
      for (String word : dialogueWords) {
        if (textWidth(tempLine + word) >= width-130) {
          if (lineCount == 3) {
            fixedDialogue.add(tempLine);
            lineCount = 0;
            tempLine = word + " ";
          } else {
            tempLine += "\n" + word + " ";
          }
          lineCount++;
        } else {
          tempLine += word + " ";
        }
      }

      //strip off last space
      if (lineCount > 0) {
        tempLine = tempLine.substring(0, tempLine.length()-1);
        fixedDialogue.add(tempLine);
      } else {
        fixedDialogue.set(fixedDialogue.size()-1, fixedDialogue.get(fixedDialogue.size()-1).substring(0, tempLine.length()-1));
      }
    } else {
      //else, if it fits the textbox already, just append to the array
      fixedDialogue.add(line);
    }
  }  

  return fixedDialogue.toArray(new String[fixedDialogue.size()]);
}

class Character {
  String name;
  PImage sprite;
  PVector position;
  public String[] dialogue;
  public SoundFile[] soundeffects;
  public boolean selected = false;

  public Character(String characterName, PImage characterSprite, String[] characterDialogue, SoundFile[] characterSfx) {
    name = characterName;
    sprite = characterSprite;
    dialogue = characterDialogue;
    soundeffects = characterSfx;
  }

  public void show() {
    //show the character sprite
    if (selected) {
      image(sprite, position.x, position.y, 200, 200);
    } else {
      image(sprite, position.x, position.y, 100, 100);
    }
  }
}

void playSound() {
  //play a random sound from the currently selected character
  if (dialogueSfx != null) {
    dialogueSfx.stop();
  }
  dialogueSfx = characters[selection].soundeffects[int(random(characters[selection].soundeffects.length-1))];
  dialogueSfx.play();
}

SoundFile[] getDialogueSounds(String characterName) {
  ArrayList<SoundFile> soundfx = new ArrayList<SoundFile>();

  //the location of the sounds
  String path = sketchPath() + "/data/sound/characters/" + characterName + "/";
  int fileCount = 0;

  //amount of files to load
  try {
    fileCount = new File(path).list().length;
  } 
  catch (NullPointerException n) {
    println("The character " + characterName + " doesn't have any speech soundeffect. muted.");
  }

  for (int i = 1; i <= fileCount; i++) {
    soundfx.add(new SoundFile(this, path + characterName + "_" + i + ".wav"));
    println("loading: " + path + characterName + "_" + i + ".wav");
  }

  return soundfx.toArray(new SoundFile[soundfx.size()]);
}

void draw() {
  if (writeText) {
    //write a letter every n frames
    if (letterIndex < characters[selection].dialogue[dialogueIndex].length()) {
      if (frameCount%dialogueSpeed==0) {        
        letterIndex++;
        soundfxTimer++;
        textSize(18);
        //display the text
        text(characters[selection].dialogue[dialogueIndex].substring(0, letterIndex), 40, height/2 + 130);

        //play sound every nth letter if the current character has any soundeffects assigned
        if (letterIndex == 0 || soundfxTimer == soundfxSpeed + soundfxCurrentVariance && characters[selection].soundeffects.length > 0) {
          playSound();
          soundfxTimer = 0;
          soundfxCurrentVariance = int(random(soundfxSpeedVariance*2)-(soundfxSpeedVariance/2));
        }
      }
    } else {
      letterIndex = 0;
      writeText = false;
    }
  }
}
