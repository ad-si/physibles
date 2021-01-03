//// Frame
frameHalfWidth = 70.5; // mm
frameDepth = 17.766666; // mm

bridgeWidth = 17; // mm
frameHeight = 40; // mm


//// Lens
glassThickness = 3; // mm
glassWidth = 54.2; // mm
glassHeight = 34; // mm
// Calculated in radius_glass_calculation.slvs
glassRadius = 91.6; // mm


hingeCutoutHeight = 3.2; // mm
hingeCutoutWidth = 5; // mm


module stackedCylinder (ridgeHeight = 1, ridgeThickness = 2) {
  cylinder(h = ridgeThickness/2, r1 = ridgeHeight, r2 = 0);
  translate([0,0,-(ridgeThickness/2)])
    cylinder(h = ridgeThickness/2, r1 = 0, r2 = ridgeHeight);
}


module sphereSlice (thickness) {
  resolution = 50; // 15 - 200
  difference () {
    spRadius = glassRadius;
    translate([0, 0, -spRadius])
      sphere(r = spRadius, $fn = resolution);
    translate([0, 0, -spRadius -  thickness])
      sphere(r = spRadius, $fn = resolution);
  }
}


module glassSlice (thickness) {
  intersection () {
    translate([-glassWidth/2, -glassHeight/2])
      linear_extrude(height = 1000, center = true)
      import (file = "./tracings/lens_outline.svg");

    sphereSlice(thickness);
  }
}


module glass () {
  brimDepth = 20;
  sliceThickness = 2;
  empiricalOffset = 12.65;

  // FIXME: This is technically not correct,
  // since a vertically moved "stackedCylinder"
  // creates a round ridge, and not a sharp ridge.
  // I couldn't come up with a better way to implement this,
  // but since the lens is pretty flat, it's good enough.
  // Also seems to cause non-manifold edges sometimes,
  // but not bad enough to cause problems in slicers.
  translate([0, 0, sliceThickness/2 + empiricalOffset])
    minkowski() {
      glassSlice(0.0001);
      stackedCylinder(ridgeThickness=sliceThickness);
    }

  translate([0, 0, (brimDepth/2) + empiricalOffset])
    glassSlice(thickness=brimDepth);
}

module hingeCutout (cutoutDepth = 3) {

  linear_extrude(height = 3, center = true)
    import (file = "./tracings/hinge_cutout.svg");
}

module frameFrontHalf () {
  difference () {
    linear_extrude(height = frameDepth * 1.5, center = true)
      import (file = "./tracings/frame_front.svg");

    cutoutDepth = 3;
    translate([frameHalfWidth - 7, frameHeight - 9, cutoutDepth - 10.4])
      // Cutout depth is just a guess,
      // because it can't be measured as it is hidden
      hingeCutout(cutoutDepth);
  }
}


module frameTopHalf () {
  linear_extrude(height = frameHeight * 1.5, center = true)
    import (file = "./tracings/frame_top.svg");
}



module frame () {
  // This is necessary to avoid non manifold edges
  overlap = 0.001;

  intersection () {
    group () {
      translate([0, -frameHeight/2])
      union () {
        translate([-overlap, 0, 0])
          frameFrontHalf();
        mirror([1,0,0])
          translate([-overlap, 0, 0])
          frameFrontHalf();
      }
    }
    group () {
      rotate([270, 0, 0])
      translate([0, -frameDepth/2, 0, ])
      union () {
        translate([-overlap, 0, 0])
          frameTopHalf();
        mirror([1,0,0])
          translate([-overlap, 0, 0])
          frameTopHalf();
      }
    }
  }
}


module lensPositioned () {
  // Following values were determined by visually checking
  // that the lens is in the center of the frame
  empiricalOffset = -2;

  empiricalPitch = 9.5;
  empiricalRoll = -1;
  empiricalYaw = 0;

  translate([glassWidth/2 + bridgeWidth/2 + empiricalOffset, 0, 0])
    rotate([empiricalYaw, empiricalPitch, empiricalRoll])
    glass();
}


difference () {
  translate([0, 0, frameDepth/2])
    frame();

  lensPositioned();

  mirror([1, 0, 0])
    lensPositioned();
}




