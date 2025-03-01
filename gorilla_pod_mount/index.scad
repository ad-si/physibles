// This should be printed with following settings for better strength:
// - Seam position: Nearest
// - 5 walls
// - 25% infill density
// - honeycomb infill pattern
// The screw thread might be to tight -> adjust `manualShaftCompensation`.

include <poly_screw_thread_r1.scad>

$fn = 50;

module gorillaPodMount() {
  length = 40;
  widthBase = 33;
  widthTip = 27;
  depthRange = [ 3.1, 2.7 ]; // TODO: Implement long slope
  completeDepth = 6;
  shortSlopeLength = 8.5;
  shortSlopeAngle = 12;
  shaftLength = 10;
  shaftDiameter = 15.875; // 5/8 inch

  module adapterWithoutGap() {
    module basePlate() {
      module basePlateHalf() {
        union() {
          hull() {
            polygon([
              [ 0, 0 ], [ length, 0 ], //
              [ length - 8, widthTip / 2 ], [ 0, widthTip / 2 ]
            ]);

            // Corner ~~ (length, 11.5)
            translate([ length - 4, 7.5 ]) circle(r = 4);
          }

          polygon([
            [ 0, 0 ], [ length, 0 ], //
            [ length - 11, (widthTip / 2) ], [ 0, widthBase / 2 ]
          ]);
        }
      }

      basePlateHalf();

      mirror([ 0, 1, 0 ]) basePlateHalf();
    }

    module topPlate() {
      module topPlateHalf() {
        hull() {
          polygon([ [ 0, 0 ], [ length, 0 ], [ 0, 12 ] ]);

          // Corner ~~ (length, 8)
          translate([ length - 5, 3.5 ]) circle(r = 5);
        }
      }

      topPlateHalf();

      mirror([ 0, 1, 0 ]) { topPlateHalf(); }
    }

    difference() {
      linear_extrude(depthRange[1]) basePlate();

      // Subtract short slope in the front
      translate([ length - shortSlopeLength, -widthBase / 2, depthRange[1] ])
          rotate([ 0, shortSlopeAngle, 0 ])
              cube(size = [ 20, widthBase, depthRange[1] ], center = false);
    }

    linear_extrude(completeDepth) topPlate();
  }

  module bottomGap() {
    translate([ 0, 5, 0 ])   //
        rotate([ 90, 0, 0 ]) //
        linear_extrude(10)   //
        polygon(
            [[length - 1, -1], [length - 1, 0], [length - 1.5, 3],
             [length - 6, 0], [length - 6, -1]]
        );
  }

  module gorillapodAdapter() {
    difference() {
      adapterWithoutGap();
      bottomGap();
    }
  }

  module thread() {
    translate([ 18, 0, 0 ]) {
      translate([ 0, 0, shaftLength + completeDepth ]) //
          screw_thread(
              shaftDiameter, // ~15.875 mm = 5/8 inch
              0.94,          // 27 threads/inch
              60,            // Standard for UNC/UNS threads
              8,             // Thread length
              1,             // Standard symmetry for threads
              2              // Common chamfer style
          );

      cylinder(d = shaftDiameter, h = shaftLength + completeDepth);
    }
  }

  // Cut off 2 mm from the end to make it protrude less
  difference() {
    gorillapodAdapter();
    translate([ -3, 0, 0 ])
        cube(size = [ 10, widthBase * 2, completeDepth * 3 ], center = true);
  }
  thread();
}

gorillaPodMount();
