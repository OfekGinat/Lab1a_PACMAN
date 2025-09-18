// HartsMatrixBitMap File 
// A two level bitmap. dosplaying harts on the screen Feb 2025 
//(c) Technion IIT, Department of Electrical Engineering 2025 



module	HartsMatrixBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic random_hart,
					input logic collision_Smiley_Hart,

					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout  //rgb value from the bitmap 
 ) ;
 

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 


localparam  int TILE_NUMBER_OF_X_BITS = 5;  // 2^5 = 32  everu object 
localparam  int TILE_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 

localparam  int MAZE_NUMBER_OF__X_BITS = 5;  // 2^5 = 32 / /the maze of the objects 
localparam  int MAZE_NUMBER_OF__Y_BITS = 4;  // 2^4 = 16 

//-----

localparam  int TILE_WIDTH_X = 1 << TILE_NUMBER_OF_X_BITS ;
localparam  int TILE_HEIGHT_Y = 1 <<  TILE_NUMBER_OF_Y_BITS ;
localparam  int MAZE_WIDTH_X = 1 << MAZE_NUMBER_OF__X_BITS;
localparam  int MAZE_HEIGHT_Y = 1 << MAZE_NUMBER_OF__Y_BITS;


 logic [10:0] offsetX_LSB  ;
 logic [10:0] offsetY_LSB  ; 
 logic [10:0] offsetX_MSB ;
 logic [10:0] offsetY_MSB  ;

 assign offsetX_LSB  = offsetX[(TILE_NUMBER_OF_X_BITS-1):0] ; // get lower bits 
 assign offsetY_LSB  = offsetY[(TILE_NUMBER_OF_Y_BITS-1):0] ; // get lower bits 
 assign offsetX_MSB  = offsetX[(TILE_NUMBER_OF_X_BITS + MAZE_NUMBER_OF__X_BITS -1 ):TILE_NUMBER_OF_X_BITS] ; // get higher bits 
 assign offsetY_MSB  = offsetY[(TILE_NUMBER_OF_Y_BITS + MAZE_NUMBER_OF__Y_BITS -1 ):TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
 

 
// the screen is 640*480  or  20 * 15 squares of 32*32  bits ,  we wiil round up to 8 *16 
// this is the bitmap  of the maze , if there is a specific value  the  whole 32*32 rectange will be drawn on the screen
// there are  16 options of differents kinds of 32*32 squares 
// all numbers here are hard coded to simplify the understanding 


logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]  MazeBitMapMask ;  

logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]   MazeDefaultBitMapMask= // defult table to load on reset 
//top wall index = 0
//bottom wall index = 13
//left wall index = 0
//righ wall index = 19
{{64'h1111111111111111111100000000000},//top wall
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1000000000000000111100000000000},
 {64'h1111111111111111111100000000000}, // down wall
 {64'h1111111111111111111100000000000}};

//{{64'h10000000000000000001},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h00000000000000000000},
// {64'h10000000000000000001}};





 logic [1:0] [0:(TILE_HEIGHT_Y-1)][0:(TILE_WIDTH_X-1)] [7:0]  object_colors  = {
{{8'hf5,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hfd,8'hf9,8'hf5},
	{8'hcc,8'hf5,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf4,8'hf4},
	{8'hcc,8'hcc,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf5,8'hf0,8'hf4},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf9,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf0,8'hf4},
	{8'hcc,8'hec,8'hf0,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf9,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf0,8'hf0},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf0,8'hf4},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf0,8'hf4},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf0,8'hf4},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf4,8'hf0,8'hf4},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf0,8'hf4},
	{8'hcc,8'hcc,8'hec,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf0,8'hf4},
	{8'hcc,8'hcc,8'hec,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4},
	{8'hcc,8'hcc,8'hec,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf9,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf5,8'hf4,8'hf5,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf0},
	{8'hcc,8'hcc,8'hec,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf4,8'hf4,8'hf0,8'hf0},
	{8'hcc,8'hcc,8'hec,8'hf4,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4},
	{8'hcc,8'hcc,8'hec,8'hf4,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4},
	{8'hcc,8'hcc,8'hec,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf9,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf0},
	{8'hcc,8'hcc,8'hec,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf0,8'hf4,8'hf0},
	{8'hcc,8'hcc,8'hec,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf9,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf0},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf9,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf5,8'hf4,8'hf5,8'hf5,8'hf0,8'hf0,8'hf0},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf0,8'hf0,8'hf0},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf0},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf0,8'hf4,8'hf0},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf0,8'hf4,8'hf0},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf5,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf0,8'hf4,8'hf0},
	{8'hcc,8'hcc,8'hf0,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf9,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf0,8'hf4,8'hf0},
	{8'hcc,8'hec,8'hf0,8'hf4,8'hf5,8'hf9,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf0,8'hf0,8'hf0},
	{8'hcc,8'hf0,8'hf0,8'hf4,8'hf5,8'hf5,8'hf4,8'hf5,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf5,8'hf4,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf0,8'hf0,8'hf0},
	{8'hcc,8'hcc,8'hec,8'hc4,8'hcc,8'hcc,8'hcc,8'hcc,8'hc4,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hc4,8'hc4,8'hc4,8'hcc,8'hc4,8'hcc,8'hc4,8'hc4,8'hc4,8'ha4,8'hc4,8'hc4,8'hcc,8'hcc,8'hf0,8'hf0,8'hf0},
	{8'hcc,8'hcc,8'hcc,8'hc4,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hc4,8'hc4,8'hc4,8'hcc,8'hc4,8'hcc,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hcc,8'hcc,8'hcc,8'hcc,8'hf0,8'hf0},
	{8'hcc,8'hc4,8'hcc,8'hcc,8'hcc,8'hc4,8'hcc,8'hcc,8'hcc,8'hc4,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hc4,8'hc4,8'hc4,8'hcc,8'hc4,8'hcc,8'hc4,8'hc4,8'hc4,8'ha4,8'hc4,8'hc4,8'hcc,8'hcc,8'hcc,8'hcc,8'hf0}
},
{
	{8'hda,8'hb5,8'hb6,8'hb6,8'hff,8'hda,8'h92,8'h92,8'h92,8'h92,8'h72,8'h31,8'h0d,8'h0d,8'h0d,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h0d,8'h72,8'h2d,8'h2d,8'h72,8'h72,8'h92,8'h6e,8'h6e,8'h96,8'h72},
	{8'hfa,8'hb5,8'hd6,8'hd6,8'hff,8'hda,8'h96,8'hb6,8'hb6,8'h72,8'h96,8'h76,8'h31,8'h31,8'h05,8'h05,8'h05,8'h25,8'h72,8'h72,8'h31,8'h0d,8'h05,8'h05,8'h05,8'h05,8'h05,8'h2d,8'h72,8'h72,8'h72,8'h2d},
	{8'hfa,8'hd6,8'hd6,8'hd6,8'hfb,8'hd6,8'h91,8'hb6,8'hb6,8'h92,8'h96,8'h72,8'h32,8'h32,8'h05,8'h05,8'h05,8'h71,8'hb6,8'hb6,8'hbb,8'h2d,8'h05,8'h05,8'h05,8'h25,8'h25,8'h05,8'h2d,8'h2d,8'h2d,8'h2d},
	{8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h91,8'hb6,8'h92,8'h92,8'h72,8'h96,8'h96,8'h2d,8'h2d,8'h05,8'h2d,8'h92,8'h6d,8'h92,8'h92,8'h96,8'h2d,8'h00,8'h2d,8'h2d,8'h92,8'h72,8'h72,8'h72,8'h72,8'h71,8'h72},
	{8'h6d,8'h25,8'h25,8'h25,8'h25,8'h71,8'h96,8'h0d,8'h0d,8'h0d,8'h0d,8'h05,8'h05,8'h05,8'h05,8'h0d,8'h72,8'h72,8'h96,8'h96,8'h96,8'h2d,8'h05,8'h92,8'h92,8'h6d,8'h6d,8'h2d,8'h2d,8'h2d,8'h2d,8'h6d},
	{8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h05,8'h05,8'h05,8'h32,8'h72,8'h72,8'h72,8'h32,8'h0e,8'h32,8'h96,8'h96,8'h96,8'h96,8'h6d,8'h25,8'h71,8'h71,8'h2d,8'h2d,8'h2d,8'h6d,8'h6d,8'h6d,8'h6d},
	{8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h72,8'h96,8'h96,8'h96,8'h76,8'h0d,8'h0d,8'h32,8'h96,8'h96,8'h72,8'h2d,8'h25,8'h71,8'h71,8'h2d,8'h2c,8'h2c,8'h2c,8'h2c,8'h6d,8'h6d},
	{8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h72,8'h96,8'h76,8'h76,8'h32,8'h0d,8'h32,8'h76,8'h96,8'h96,8'h9a,8'h72,8'h2d,8'h71,8'h71,8'h2d,8'h31,8'h75,8'h31,8'h31,8'h2c,8'h65},
	{8'h31,8'h31,8'h31,8'h31,8'h31,8'h31,8'h31,8'h31,8'h31,8'h9a,8'hba,8'h9a,8'hba,8'hba,8'hba,8'h96,8'h76,8'h9a,8'h96,8'h96,8'hba,8'h96,8'h71,8'h75,8'h75,8'h35,8'h75,8'h35,8'h75,8'h75,8'h71,8'h6d},
	{8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'hba,8'hba,8'h96,8'h96,8'h96,8'hba,8'h96,8'h72,8'hb6,8'h96,8'h96,8'h96,8'hb6,8'h2d,8'h71,8'h71,8'h31,8'h71,8'h75,8'h71,8'h71,8'h6d,8'h6d},
	{8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h72,8'h91,8'h6d,8'h2d,8'h2d,8'h92,8'h72,8'h72,8'hba,8'h92,8'h92,8'h92,8'hba,8'h6d,8'h71,8'h71,8'h04,8'h2d,8'h71,8'h71,8'h71,8'h6d,8'h6d},
	{8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h96,8'hdb,8'hda,8'hba,8'hba,8'hba,8'h72,8'h72,8'hdb,8'h92,8'h92,8'hb6,8'hb6,8'h6d,8'h71,8'h71,8'h25,8'h25,8'h25,8'h25,8'h25,8'h24,8'h25},
	{8'h2e,8'h2d,8'h72,8'h72,8'h2d,8'h2d,8'h2d,8'h72,8'h72,8'h96,8'hdb,8'hb6,8'hb6,8'hb6,8'hdf,8'h96,8'h76,8'hb6,8'h71,8'h71,8'h96,8'hbb,8'h72,8'h72,8'h72,8'h92,8'h6d,8'h71,8'h6d,8'h6d,8'h2d,8'h6d},
	{8'h96,8'hdf,8'hbb,8'hbb,8'h92,8'hdf,8'h96,8'h96,8'h96,8'h9b,8'h96,8'h72,8'h72,8'h72,8'h92,8'h9b,8'h72,8'h96,8'hb6,8'hb6,8'h72,8'h72,8'h96,8'h96,8'h96,8'h72,8'h05,8'h2d,8'h2e,8'h2e,8'h6e,8'h2d},
	{8'h2d,8'hbb,8'h6d,8'h6d,8'h92,8'h96,8'hdb,8'h96,8'h96,8'h72,8'h0d,8'h0d,8'h2d,8'h2d,8'h71,8'h72,8'h96,8'hdb,8'hbb,8'hbb,8'h72,8'h96,8'h96,8'hb7,8'hb7,8'h96,8'h0d,8'h05,8'h2d,8'h2d,8'h2d,8'h05},
	{8'h2d,8'h96,8'h96,8'h96,8'h96,8'h25,8'hbb,8'hdf,8'hdf,8'h72,8'h2d,8'h2d,8'h96,8'h96,8'hdf,8'hbb,8'hbb,8'hff,8'hff,8'hff,8'hb6,8'h96,8'h72,8'h96,8'h96,8'h96,8'h05,8'h25,8'h92,8'h92,8'h96,8'h96},
	{8'h96,8'h96,8'hb6,8'hb6,8'h96,8'h72,8'h96,8'h96,8'h96,8'h96,8'h2e,8'h96,8'h96,8'h96,8'hdb,8'hba,8'h96,8'hb6,8'hb6,8'hb6,8'h92,8'hb6,8'h92,8'h96,8'h96,8'h96,8'h6d,8'h72,8'hba,8'hba,8'hba,8'hdb},
	{8'h32,8'h72,8'h72,8'h72,8'h72,8'h72,8'h72,8'h72,8'h72,8'h2d,8'h72,8'h72,8'h92,8'h92,8'hba,8'h96,8'h96,8'hda,8'hda,8'hda,8'h96,8'hb6,8'h92,8'h96,8'h96,8'h96,8'h92,8'hb6,8'h92,8'h92,8'h6d,8'h91},
	{8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h72,8'h97,8'h96,8'h96,8'hba,8'hb6,8'hb6,8'h92,8'hb6,8'hb6,8'h92,8'hb6,8'h92,8'hb6,8'hb6,8'hbb,8'h96,8'hb6,8'h92,8'h92,8'h71,8'h91},
	{8'h05,8'h05,8'h05,8'h05,8'h0d,8'h0d,8'h0d,8'h05,8'h05,8'h05,8'h0d,8'h2d,8'h96,8'h96,8'h96,8'hba,8'hba,8'h72,8'h6d,8'h6d,8'h92,8'h72,8'h72,8'h92,8'h92,8'h72,8'h92,8'h96,8'h96,8'h96,8'h92,8'h96},
	{8'h05,8'h05,8'h05,8'h05,8'h05,8'h0d,8'h0d,8'h05,8'h05,8'h05,8'h0d,8'h32,8'h76,8'h76,8'h96,8'hbb,8'h72,8'h2d,8'h2d,8'h2d,8'h25,8'h2d,8'h96,8'h72,8'h72,8'h05,8'h05,8'h2d,8'h96,8'h96,8'h92,8'h96},
	{8'h05,8'h72,8'h05,8'h05,8'h72,8'h0d,8'h05,8'h0d,8'h0d,8'h05,8'h2e,8'h72,8'h2e,8'h2e,8'h72,8'h96,8'h72,8'h05,8'h05,8'h05,8'h2d,8'h2d,8'h72,8'h72,8'h72,8'h2d,8'h2d,8'h05,8'h0d,8'h0d,8'h2d,8'h2d},
	{8'h72,8'hbb,8'h6d,8'h6d,8'hb6,8'h32,8'h05,8'h05,8'h05,8'h05,8'h72,8'h96,8'h2e,8'h2e,8'h05,8'h96,8'h96,8'h2e,8'h05,8'h05,8'h72,8'h96,8'h2d,8'h2d,8'h2d,8'h9b,8'h96,8'h0d,8'h05,8'h05,8'h05,8'h0d},
	{8'h71,8'h6d,8'h6d,8'h6d,8'h6d,8'h72,8'h05,8'h05,8'h05,8'h6e,8'h92,8'h96,8'h92,8'h92,8'h72,8'h96,8'h96,8'h72,8'h72,8'h72,8'h72,8'h96,8'h72,8'h72,8'h72,8'h96,8'h96,8'h72,8'h05,8'h05,8'h05,8'h0d},
	{8'h92,8'h2d,8'h00,8'h00,8'h6d,8'h2d,8'h05,8'h05,8'h05,8'h72,8'hff,8'hff,8'hb6,8'hb6,8'hb6,8'hff,8'hff,8'hb6,8'hb6,8'hb6,8'hff,8'hff,8'h96,8'hb6,8'hb6,8'hff,8'hff,8'h92,8'h25,8'h25,8'h96,8'hb6},
	{8'h2d,8'h72,8'h2d,8'h2d,8'h92,8'h2d,8'h05,8'h05,8'h05,8'h92,8'hff,8'hff,8'h91,8'h91,8'h96,8'hff,8'hff,8'h91,8'h92,8'h92,8'h6d,8'h6d,8'h92,8'h96,8'h96,8'h2d,8'h2d,8'h92,8'h25,8'h25,8'h96,8'hb6},
	{8'h2d,8'h72,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h72,8'hff,8'hff,8'h91,8'h91,8'h91,8'hff,8'hff,8'h71,8'h96,8'h96,8'hda,8'hb6,8'h92,8'hb6,8'hb6,8'hba,8'hb6,8'h92,8'h25,8'h25,8'h96,8'hb6},
	{8'h72,8'h2d,8'h72,8'h72,8'h2e,8'h72,8'h72,8'h2d,8'h2d,8'h92,8'h96,8'h96,8'h92,8'h92,8'h96,8'h91,8'h92,8'h92,8'h96,8'h96,8'hff,8'hdf,8'h96,8'hbb,8'hbb,8'hdf,8'hbb,8'h92,8'h25,8'h25,8'h92,8'h96},
	{8'h96,8'h72,8'h96,8'h96,8'h72,8'hb6,8'h96,8'h72,8'h72,8'hb6,8'hbb,8'hba,8'hbb,8'hbb,8'h96,8'hba,8'hba,8'hb6,8'h96,8'h96,8'hba,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hba,8'h96,8'h05,8'h05,8'h05,8'h05},
	{8'h76,8'h72,8'h72,8'h72,8'h72,8'h72,8'h72,8'h92,8'h92,8'h6e,8'h2d,8'h6d,8'h72,8'h72,8'h6d,8'h92,8'h72,8'h6d,8'h72,8'h72,8'h92,8'h72,8'h72,8'h6d,8'h6d,8'h92,8'h92,8'h72,8'h6e,8'h6e,8'h2d,8'h2e},
	{8'h0d,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h05,8'h25,8'h2d,8'h2d,8'h2d,8'h2d,8'h6d,8'h2d,8'h71,8'h71,8'h2d,8'h6d,8'h6d,8'h2d,8'h2d,8'h2d,8'h2d,8'h6d,8'h6d,8'h6d,8'h2d,8'h92},
	{8'h0d,8'h0d,8'h0d,8'h0d,8'h0d,8'h0d,8'h0d,8'h0d,8'h0d,8'h05,8'h05,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d}}};
 
//
// pipeline (ff) to get the pixel color from the array 	 

//==----------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		MazeBitMapMask  <=  MazeDefaultBitMapMask ;  //  copy default tabel 
	end
	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default 
		if (collision_Smiley_Hart)
			MazeBitMapMask[offsetY_MSB][offsetX_MSB] <= 4'h00;  // clear entry 
		
		if (InsideRectangle == 1'b1 )	
			begin 
		   	case (MazeBitMapMask[offsetY_MSB][offsetX_MSB])
					 4'h0 : RGBout <= TRANSPARENT_ENCODING ;
					 4'h1 : RGBout <= object_colors[4'h1][offsetY_LSB][offsetX_LSB]; 
					 4'h2 : RGBout <= object_colors[4'h1][offsetY_LSB][offsetX_LSB] ; 
					 default:  RGBout <= TRANSPARENT_ENCODING ; 
				endcase
			end 

	end 
end

//==----------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
endmodule

