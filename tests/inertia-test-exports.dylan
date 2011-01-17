module:    dylan-user
synopsis:  Inertia-test exports
author:    Mike Austin
copyright: Copyright (C) 2005 Mike L. Austin.  All rights reserved.
license:   MIT/BSD, see LICENCE.txt for details

//
// inertia-test-exports.dylan
//

define library inertia-test
  use common-dylan;
  use transcendental;
  use time;
  use melange-support;
  use opengl;
  use inertia;
end;

define module inertia-test
  use common-dylan;
  use transcendental;
  use melange-support;
  use opengl;
  use opengl-glut;
  use simple-io;
  use time;
  use inertia;
  use inertia-shapes;
end;

