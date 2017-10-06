import processing.serial.*;

static final String PORT = "/dev/ttyUSB0"; // Serial port
static final int MAX_VALUES = 80;
static final char PROTOCOL_HDR1 = 'M'; // Magic
static final char PROTOCOL_HDR2 = 'V'; // Value
static int [] data;

static final int COLOR_MAX = 4095;

Serial usbPort;  // Create object from Serial class

// convert unsigned byte to int
int unsigned(byte val) {
  return int(val) & 0xff;
}

int receive_message() {
  byte [] res = null;

  print("Receiving message... ");
  // find message start
  do {
    while ((res == null) || (res[0] != PROTOCOL_HDR1)) {
      res = usbPort.readBytes(1);
    }
    res = usbPort.readBytes(1);
  } while ((res == null) || (res[0] != PROTOCOL_HDR2));
  print("found header ...  ");

  // read length
  res = usbPort.readBytes(1);
  if (res == null)
    return 0;

  int len = int(res[0]);
  print(len);
  println(" values");

  if (len > MAX_VALUES)
    len = MAX_VALUES;

  // read data
  res = usbPort.readBytes(len * 2);
  if (res == null)
    return 0;

  len = res.length / 2;
  for (int idx = 0; idx < len; idx++) {
    data[idx] = unsigned(res[(2 * idx)]) + 256 * unsigned(res[(2 * idx) + 1]);
  }

  for (int val : data) {
    print(val);
    print(' ');
  }
  println();

  return len;
}

// 2D Array of objects
Cell[][] grid;

// Number of columns and rows in the grid
int cols = 5;
int rows = 16;

int nearest_neighbor(int x, int y) {
  int idx = (rows * (x / (width / cols))) + (y / (height / rows));
  return data[idx];
}

int bilinear(int x, int y) {
  int xfull = width / cols;
  int yfull = height / rows;
  int max_idx = cols * rows;

  int idx_lu = (rows * (x / xfull)) + (y / yfull);
  int idx_ld = (((idx_lu + 1) < max_idx) && ((idx_lu + 1) % rows > 0)) ? idx_lu + 1 : idx_lu;
  int idx_ru = (idx_lu + rows) < max_idx ? idx_lu + rows : idx_lu;
  int idx_rd = (((idx_ru + 1) < max_idx) && ((idx_ru + 1) % rows > 0)) ? idx_ru + 1 : idx_ru;

  int xdiff = (x % xfull);
  int ydiff = (y % yfull);

  int data_left = ((yfull - ydiff) * data[idx_lu] + (ydiff * data[idx_ld])) / yfull;
  int data_right = ((yfull - ydiff) * data[idx_ru] + (ydiff * data[idx_rd])) / yfull;
  int data_mid = ((xfull - xdiff) * data_left + (xdiff * data_right)) / xfull;

  return data_mid;
}

void setup() {
  blendMode(BLEND);

  data = new int[MAX_VALUES];
  usbPort = new Serial(this, PORT, 115200);
  // FIXME: wait a little here for reliable connection
  do {
    delay(2000);
  } while (usbPort.readBytes(1) == null);

  size(400,640);

  grid = new Cell[cols][rows];
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      // Initialize each object
      grid[i][j] = new Cell(i*40,j*40,40,40,i+j);
    }
  }

  colorMode(HSB, 360, 100, 100);
}

void draw() {
  blendMode(BLEND);
  background(0);

  receive_message();

  // The counter variables i and j are also the column and row numbers and
  // are used as arguments to the constructor for each object in the grid.
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      // Oscillate and display each object
//      grid[i][j].oscillate();
      grid[i][j].display();
    }
  }

  int width = 200;
  int height = 640;
  int colr = 0;

  for (int x = 0; x < width; x += 10) {
    for (int y = 0; y < height; y += 4) {
//      colr = nearest_neighbor(x, y);
      colr = bilinear(x, y);
//      stroke(colr, colr < (COLOR_MAX - colr) ? 2 * colr : 2 * (COLOR_MAX - colr), COLOR_MAX - colr);
//      fill(colr, colr < (COLOR_MAX - colr) ? 2 * colr : 2 * (COLOR_MAX - colr), COLOR_MAX - colr);

      if (colr > COLOR_MAX)
        colr = COLOR_MAX;

      // rotate Hue between 0 and 220 degrees
      int angle = (220 * (COLOR_MAX - colr)) / COLOR_MAX;
      stroke(angle, 100, 100);
      fill(angle, 100, 100);
      rect(200 + x, y, 10, 4);
    }
  }
}

// A Cell object
class Cell {
  // A cell object knows about its location in the grid
  // as well as its size with the variables x,y,w,h
  float x,y;   // x,y location
  float w,h;   // width and height
  float angle; // angle for oscillating brightness

  // Cell Constructor
  Cell(float tempX, float tempY, float tempW, float tempH, float tempAngle) {
    x = tempX;
    y = tempY;
    w = tempW;
    h = tempH;
    angle = tempAngle;
  }

  // Oscillation means increase angle
  void oscillate() {
    angle += 0.02;
  }

  void display() {
//    stroke(255);
    // Color calculated using sine wave
//    fill(127+127*sin(angle));

    int idx = floor((rows * (x / 40)) + ((y / 40)));
    int colr = data[idx];
//    stroke(colr, 0, COLOR_MAX - colr);
//    fill(colr, 0, COLOR_MAX - colr);
//    stroke(colr, colr < (COLOR_MAX - colr) ? 2 * colr : 2 * (COLOR_MAX - colr), COLOR_MAX - colr);
//    fill(colr, colr < (COLOR_MAX - colr) ? 2 * colr : 2 * (COLOR_MAX - colr), COLOR_MAX - colr);

      if (colr > COLOR_MAX)
        colr = COLOR_MAX;

      // rotate Hue between 0 and 220 degrees
      int angle = (220 * (COLOR_MAX - colr)) / COLOR_MAX;
      stroke(angle, 100, 100);
      fill(angle, 100, 100);

    rect(x,y,w,h);
  }
}
