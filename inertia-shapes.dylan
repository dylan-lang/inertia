module:    inertia-shapes
synopsis:  Core UI shapes
author:    Mike Austin
copyright: Copyright (C) 2005 Mike L. Austin.  All rights reserved.
license:   MIT/BSD, see LICENCE.txt for details

//
// inertia-shapes.dylan
//

define variable *angle* = 0.0;

// ---------------------------------------------------------------------------------------------- //
// all class definitions
// ---------------------------------------------------------------------------------------------- //

define class <shape> (<object>)
  slot delegate :: subclass(<shape>), init-keyword: delegate:;
  slot children = make (<deque>);
  slot parent :: false-or (<shape>);
  slot origin = make(<point>, x: 0.0, y: 0.0);
  slot %extent = make(<point>, x: 100.0, y: 100.0);
  slot z-angle :: <double-float> = 0.0;
  slot z-scale :: <double-float> = 1.0;
  slot mouse-mode = #"normal";
  slot fill-color :: <vector> = vector (random-float (0.5) + 0.5, random-float (0.5) + 0.5, random-float (0.5) + 0.5, 0.9);
  slot line-color = vector (0.0, 0.0, 0.0, 1.0);
  slot line-width = 3.0;
  slot effects :: <vector> = #[];
  slot reshape = #[#"none", #"none"], init-keyword: reshape:;
  virtual slot extent :: <point>;
  virtual slot shape-left :: <double-float>;
  virtual slot shape-top :: <double-float>;
  virtual slot shape-width :: <double-float>;
  virtual slot shape-height :: <double-float>;
end;

define method class-name (shape :: <shape>) "<shape>" end;

define class <container> (<shape>)
end;

define class <polygon> (<shape>)
  slot data = #[
    #[0.0, 0.0,  0.0], #[15.0,  50.0,  0.0], #[0.0, 100.0,  0.0], #[50.0,  85.0,  0.0],
    #[ 100.0,  100.0,  0.0], #[ 85.0,  50.0,  0.0], #[100.0, 0.0,  0.0], #[50.0, 15.0,  0.0]
  ];
  slot data2 = #[
    #[-50.0, -50.0,  0.0], #[-35.0,  0.0,  0.0], #[-50.0, 50.0,  0.0], #[0.0,  35.0,  0.0],
    #[ 50.0,  50.0,  0.0], #[ 35.0,  0.0,  0.0], #[50.0, -50.0,  0.0], #[0.0, -35.0,  0.0]
  ];
  slot vertices;
end;

define class <spinning-polygon> (<polygon>)
  inherited slot effects = vector (make (<shadow-effect>));
end;

define method class-name (polygon :: <polygon>) "<polygon>" end;

define class <rectangle> (<shape>)
end;

define method class-name (rectangle :: <rectangle>) "<rectangle>" end;

define class <screen> (<rectangle>)
  inherited slot fill-color = vector (1.0, 1.0, 1.0, 1.0);
  slot mouse-origin :: <point>;
  slot grabbed-shape :: false-or (<shape>) = #f;
end;

define method class-name (screen :: <screen>) "<screen>" end;

define class <shape-menu-center> (<rectangle>)
  inherited slot fill-color = vector (0.5, 0.5, 0.5, 0.9);
  inherited slot line-width = 1.0;
  keyword width: = 120.0;
  keyword height: = 120.0;
end;

define class <shape-menu> (<rectangle>)
  inherited slot fill-color = vector (0.5, 0.5, 0.5, 0.9);
  inherited slot line-width = 1.0;
end;

define method initialize (menu :: <shape-menu>, #rest init-args, #key) => ()
  next-method ();
  add-child (menu, make (<shape-menu-center>, left: menu.shape-width / 2.0 - 60.0, top: menu.shape-height / 2.0 - 60.0));
end;

define method class-name (menu :: <shape-menu>) "<shape-menu>" end;

// ---------------------------------------------------------------------------------------------- //
// shape methods definitions
// ---------------------------------------------------------------------------------------------- //

// - slot getters and setters ------------------------------------------------------------------- //

define method shape-left (shape :: <shape>) => (result :: <double-float>)
  shape.origin.point-x;
end;

define method shape-left-setter (value :: <double-float>, shape :: <shape>)
 => (result :: <double-float>)
  shape.origin.point-x := value;
end;

define method shape-top (shape :: <shape>)
 => (result :: <double-float>)
  shape.origin.point-y;
end;

define method shape-top-setter (value :: <double-float>, shape :: <shape>)
 => (result :: <double-float>)
  shape.origin.point-y := value;
end;

define method shape-width (shape :: <shape>) => (result :: <double-float>)
  shape.extent.point-x;
end;

define method shape-width-setter (value :: <double-float>, shape :: <shape>)
 => (result :: <double-float>)
  shape.extent.point-x := value;
  // send <shape-reshape-event>
end;

define method shape-height (shape :: <shape>)
 => (result :: <double-float>)
  shape.extent.point-y;
  // send <shape-reshape-event>
end;

define method shape-height-setter (value :: <double-float>, shape :: <shape>)
 => (result :: <double-float>)
  shape.extent.point-y := value;
end;

define method extent (shape :: <shape>)
  shape.%extent;
end;

define method extent-setter (extent :: <point>, shape :: <shape>)
 => (result :: <point>)
  for (child in shape.children)
    send-event (child, make (<parent-reshape-event>), extent - shape.%extent);
  end;
  shape.%extent := extent;
end;

// ---------------------------------------------------------------------------------------------- //

define method screen-origin (shape :: <shape>)
  shape.origin + shape.parent.screen-origin;
end;

define method screen-origin (screen :: <screen>)
  screen.origin;
end;

// ---------------------------------------------------------------------------------------------- //

define method add-child (shape :: <shape>, child :: <shape>) => ()
  child.parent := shape;
  shape.children := add! (shape.children, child);
end;

define method remove-child (shape :: <shape>, child :: <shape>) => ()
  child.parent := shape;
  shape.children := remove! (shape.children, child);
end;

// - drawing routines --------------------------------------------------------------------------- //

define method draw-shape (shape :: <shape>) => ()
  glPushMatrix ();
    glTranslate (shape.shape-left, shape.shape-top, 0.0);
    glRotate (shape.z-angle, 0.0, 0.0, 1.0);

    glPushMatrix ();
      glScale (shape.z-scale, shape.z-scale, 0.0);

      draw-effects (shape, #"below");

      glClearStencil (#x0);
      glClear ($GL-STENCIL-BUFFER-BIT);
      glEnable ($GL-STENCIL-TEST);
      glStencilFunc ($GL-ALWAYS, #x1, #x1);
      glStencilOp ($GL-REPLACE, $GL-REPLACE, $GL-REPLACE);

      glColor (shape.fill-color[0], shape.fill-color[1], shape.fill-color[2], shape.fill-color[3]);
      draw-content (shape, if (slot-initialized? (shape, delegate)) shape.delegate else shape end);

      glStencilFunc ($GL-EQUAL, #x1, #x1);
      glStencilOp ($GL-KEEP, $GL-KEEP, $GL-KEEP);

      draw-effects (shape, #"inside");

      for (i from shape.children.size - 1 to 0 by -1)
      //for (child in shape.children using reverse-iteration-protocol)
        let child = shape.children[i];
        draw-shape (child);
      end;

      glDisable ($GL-STENCIL-TEST);

      draw-effects (shape, #"above");

      glColor (shape.fill-color[0], shape.fill-color[1], shape.fill-color[2], shape.fill-color[3]);
      draw-overlay (shape, if (slot-initialized? (shape, delegate)) shape.delegate else shape end);

      glLineWidth (as(<single-float>, shape.line-width));
      glColor (shape.line-color[0], shape.line-color[1], shape.line-color[2], shape.line-color[3]);
      draw-outline (shape);
    glPopMatrix ();
  glPopMatrix ();
end;

define method draw-effects (shape :: <shape>, layer :: <effect-layer>)
  for (effect in shape.effects)
    if (effect.effect-layer == layer) draw-effect (shape, effect) end;
  end;
end;

define constant $PI = 3.14159;

// ---------------------------------------------------------------------------------------------- //

define method draw-content (shape :: <shape>, delegate :: <shape>) => () end;
define method draw-overlay (shape :: <shape>, delegate :: <shape>) => () end;
define method draw-outline (shape :: <shape>) => () end;

define method contains-point? (shape :: <shape>, point :: <point>) => (result :: <boolean>)
  #f
end;

define method on-mouse-event (shape :: <shape>, event :: <mouse-event>, button :: <mouse-button>)
  format-out ("on-mouse-event (%=, %=, %=)\n", shape, event, button);
end;

// ---------------------------------------------------------------------------------------------- //
// polygon methods definitions
// ---------------------------------------------------------------------------------------------- //

define method initialize (polygon :: <polygon>, #rest init-args, #key left = 0.0, top = 0.0) => ()
  //apply (next-method, init-args);
  next-method ();
  format-out ("initialize (<polygon>)\n");
  polygon.shape-left := left;
  polygon.shape-top := top;
  polygon.z-angle := 5.0;

  polygon.vertices := map (method (vertex) as(<GLdouble*>, vertex) end, polygon.data);
end;

define method draw-content (shape :: <shape>, polygon :: <polygon>) => ()
  gluBeginPolygon (*tess-object*);
    for (vertex in polygon.vertices)
      gluTessVertex (*tess-object*, vertex, as(<GLvoid*>, vertex));
    end;
  gluEndPolygon (*tess-object*);
end;

define method draw-outline (polygon :: <polygon>) => ()
  glBegin ($GL-LINE-LOOP);
    for (vertex in polygon.vertices)
      glVertex (vertex[0], vertex[1], vertex[2]);
    end;
  glEnd ();
end;

define constant $X = 0;
define constant $Y = 1;
define constant $Z = 2;

define method contains-point? (polygon :: <polygon>, point :: <point>) => (result :: <boolean>)
  let x = point.point-x; let y = point.point-y;
  let v = polygon.data;
  let inside :: <boolean> = #f;

  for (i :: <integer> from 0 below v.size)
    let j :: <integer> = if (i = v.size - 1) 0 else i + 1 end;
    if (((v[i][$Y] <= y) & (v[j][$Y] > y)) | ((v[i][$Y] > y) & (v[j][$Y] <= y)))
      let vt = (y - v[i][$Y]) / (v[j][$Y] - v[i][$Y]);
      if (x < v[i][$X] + vt * (v[j][$X] - v[i][$X]))
        inside := ~inside;
      end;
    end;
  end;  

  inside;
end;

define variable *polygon* = 0;
define variable *speed* = 10;

define variable xtimer = callback-method (n :: <integer>) => ();
  if (*speed* > 0.01)
    glutTimerFunc (n, xtimer, n);
    *polygon*.z-angle := *polygon*.z-angle + *speed*;
    *speed* := *speed* * 0.9;
    glutPostRedisplay ();
  else
    *speed* := 10;
  end;
end;

define method on-mouse-event (polygon :: <spinning-polygon>, event :: <mouse-down-event>, button :: <mouse-button>)
  next-method ();
  *polygon* := polygon;
  glutTimerFunc (10, xtimer, 10);
end;

// ---------------------------------------------------------------------------------------------- //
// rectangle methods definitions
// ---------------------------------------------------------------------------------------------- //

define method initialize (rectangle :: <rectangle>, #rest init-args,
                          #key left = 0.0, top = 0.0, width = 100.0, height = 100.0) => ()
  apply (next-method, init-args);
  format-out ("initialize (<rectangle>)\n");
  rectangle.shape-left := left;
  rectangle.shape-top := top;
  rectangle.shape-width := width;
  rectangle.shape-height := height;
end;

define method draw-content (shape :: <shape>, rectangle :: <rectangle>) => ()
  let width/2 = shape.shape-width / 2.0;
  let height/2 = shape.shape-height / 2.0;

  glBegin ($GL-QUADS);
    glVertex (                 0.0,                  0.0);
    glVertex (                 0.0, shape.shape-height);
    glVertex (shape.shape-width, shape.shape-height);
    glVertex (shape.shape-width, 0.0);
  glEnd ();
end;

define method draw-outline (rectangle :: <rectangle>) => ()
  let width/2 = rectangle.shape-width / 2.0;
  let height/2 = rectangle.shape-height / 2.0;
  let shape = rectangle;

  glBegin ($GL-LINE-LOOP);
    glVertex (                 0.0,                  0.0);
    glVertex (                 0.0, shape.shape-height);
    glVertex (shape.shape-width, shape.shape-height);
    glVertex (shape.shape-width, 0.0);
  glEnd ();
end;

define method contains-point? (rectangle :: <rectangle>, point :: <point>) => (result :: <boolean>)
  let width/2 = rectangle.shape-width / 2.0;
  let height/2 = rectangle.shape-height / 2.0;

  (point.point-x > 0 & point.point-x < rectangle.shape-width)
    & (point.point-y > 0 & point.point-y < rectangle.shape-height);
end;

// ---------------------------------------------------------------------------------------------- //
// shape-menu methods definitions
// ---------------------------------------------------------------------------------------------- //

define method draw-content (shape :: <shape>, menu :: <shape-menu-center>)
  let radius = 60.0;

  glPushMatrix ();
  glTranslate (shape.shape-width / 2.0, shape.shape-height / 2.0, 0.0);
  glBegin ($GL-TRIANGLE-FAN);
    glVertex (0.0, 0.0, 0.0);
    for (angle from 0 to $PI * 2 by $PI / 20.0)
      glVertex (cos (angle) * radius, sin (angle) * radius, 0.0);
    end;
    glVertex (cos (0) * radius, sin (0) * radius, 0.0);
  glEnd ();

  glLineWidth (2.0s0);
  glColor (1.0, 1.0, 1.0, 0.7);

  glBegin ($GL-LINE-LOOP);
    for (angle from 0 to $PI * 2 by $PI / 20.0)
      glVertex (cos (angle) * radius, sin (angle) * radius, 0.0);
    end;
  glEnd ();

  glBegin ($GL-TRIANGLE-FAN);
    glVertex (0.0, 0.0, 0.0);
    for (angle from 0 to $PI * 2 by $PI / 20.0)
      glVertex (cos (angle) * 5.0, sin (angle) * 5.0, 0.0);
    end;
    glVertex (cos (0) * 5.0, sin (0) * 5.0, 0.0);
  glEnd ();

  glBegin ($GL-LINE-LOOP);
    for (angle from 0 to $PI * 2 by $PI / 20.0)
      glVertex (cos (angle) * 5.0, sin (angle) * 5.0, 0.0);
    end;
  glEnd ();
  
  glBegin ($GL-LINES);
    glVertex ( cos ($PI * (1.0 / 4.0)) * radius,  sin ($PI * (1.0 / 4.0)) * radius);
    glVertex (-cos ($PI * (1.0 / 4.0)) * radius, -sin ($PI * (1.0 / 4.0)) * radius);
    glVertex ( cos ($PI * (3.0 / 4.0)) * radius,  sin ($PI * (3.0 / 4.0)) * radius);
    glVertex (-cos ($PI * (3.0 / 4.0)) * radius, -sin ($PI * (3.0 / 4.0)) * radius);
  glEnd ();
  glPopMatrix ();
end;

define method draw-overlay (shape :: <shape>, menu :: <shape-menu-center>) => ()
  next-method ();
  let radius = 60.0;
  glPushMatrix ();
  glTranslate (shape.shape-width / 2.0, shape.shape-height / 2.0, 0.0);

  glColor (1.0, 1.0, 1.0, 1.0);

  draw-centered-string (  0, -40 + 5, "Cut");
  draw-centered-string (-35,   0 + 5, "Copy");
  draw-centered-string ( 35,   0 + 5, "Paste");
  draw-centered-string (  0,  40 + 5, "Clone");
  glPopMatrix ();
end;

define method draw-effects (menu :: <shape-menu-center>, layer :: <effect-layer>) end;
define method draw-outline (menu :: <shape-menu-center>) end;

// ---------------------------------------------------------------------------------------------- //

define method draw-overlay (shape :: <shape>, menu :: <shape-menu>) => ()
  next-method ();
  let radius = 60.0;
  glPushMatrix ();
  glTranslate (shape.shape-width / 2.0, shape.shape-height / 2.0, 0.0);

  glColor (1.0, 1.0, 1.0, 1.0);
  //draw-centered-string (0, -50 + 7, "Bring to Front");
  draw-centered-string (0, -75 + 5, "Bring Forward");
  draw-centered-string (0,  75 + 5, "Send Backward");
  //draw-centered-string (0,  50 + 7, "Send to Back");
  glPopMatrix ();
end;

define method draw-effects (menu :: <shape-menu>, layer :: <effect-layer>) end;
define method draw-outline (menu :: <shape-menu>) end;

define method draw-centered-string (x, y, string :: <string>)
  local draw-string (x, y, string)
    let width :: <integer> = glutxBitmapLength ($GLUT-BITMAP-HELVETICA-12, string);
    glRasterPos (round/ (-width, 2.0) + x, y);
    glutxBitmapString ($GLUT-BITMAP-HELVETICA-12, string);
  end;

  draw-string (x, y, string);
  draw-string (x + 1, y, string);
end;

