// VTextRenderer
// by V* (Victor Martinis)
// pixelnerve.com/v

import java.text.*;
import com.sun.opengl.util.*;
import com.sun.opengl.util.j2d.*;

class VTextRenderer
{
  VTextRenderer( String fontName, int size )
  {
    _fontName = fontName;
    _fontSize = size;
    _textRender = new TextRenderer( new Font(fontName, Font.TRUETYPE_FONT, size), true, true, null, true );
    _textRender.setColor( 1.0f, 1.0, 1.0, 1.0 );
    //_textRender.setUseVertexArrays( true );
  }
  
  VTextRenderer( Font font, int size )
  {
    _fontName = font.getFontName();
    _fontSize = size;
    _textRender = new TextRenderer( font, true, true, null, true );
    _textRender.setColor( 1.0f, 1.0, 1.0, 1.0 );
  }  
  
  VTextRenderer( String fontName, int size, boolean antialiased, boolean mipmap )
  {
    _fontName = fontName;
    _fontSize = size;
    _textRender = new TextRenderer( new Font(fontName, Font.TRUETYPE_FONT, size), antialiased, true, null, mipmap );
    _textRender.setColor( 1.0f, 1.0, 1.0, 1.0 );
    //_textRender.setUseVertexArrays( true );
  }

  void print( String str, int x, int y )
  {
    _textRender.beginRendering( width, height, true );
    _textRender.draw( str, x, y );
    _textRender.endRendering();
    _textRender.flush();
  }

  void print( String str, float x, float y, float z )
  {
    print( str, x, y, z, 1.0f );
  }

  void print( String str, float x, float y, float z, float s )
  {
    _textRender.begin3DRendering();
    _textRender.draw3D( str, x, y, z, s );
    _textRender.end3DRendering();
    _textRender.flush();
  }

  void setColor( float c )
  {
    setColor( c, c, c, 1 );
  }

  void setColor( float c, float a )
  {
    setColor( c, c, c, a );
  }

  void setColor( float r, float g, float b )
  {
    setColor( r, g, b, 1 );
  }

  void setColor( float r, float g, float b, float a )
  {
    _textRender.setColor( r, g, b, a );
  }
  
  void setColor( float[] rgba ) 
  {
    _textRender.setColor(rgba[0], rgba[1], rgba[2], rgba[3]);
  }

  void setSmoothing( boolean flag )
  {
    _textRender.setSmoothing( flag );
  }

  /// ____________________________________________________
  /// Members
  int _w, _h;

  String _fontName;
  int _fontSize;
  TextRenderer _textRender;
  Font font;
}

