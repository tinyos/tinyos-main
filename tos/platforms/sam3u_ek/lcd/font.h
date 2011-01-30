#ifndef FONT_H
#define FONT_H

//------------------------------------------------------------------------------
/// Describes the font (width, height, supported characters, etc.) used by
/// the LCD driver draw API.
//------------------------------------------------------------------------------
typedef struct _Font {

	/// Font width in pixels.
	unsigned char width;
	/// Font height in pixels.
	unsigned char height;

} Font;


#endif //#ifndef FONT_H
