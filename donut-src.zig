// Based off https://www.a1k0n.net/2011/07/20/donut-math.html

/// Torus minor radius (i.e. the radius of the tube)
const R1 = 1;
/// Torus major radius
/// (i.e. the distance from the center of the tube to the center of the torus)
const R2 = 2;

/// Distance from camera to the viewing plane. Determines FOV.
// Calculated based off screen size to ensure torus fills the frame
// without clipping the borders.
const K1 = screen_width * K2 * 3 / (8 * (R1 + R2));

/// Distance of the donut from the camera
const K2 = 5;

/// Good enough approximation...
const PI = 3.1415926;

const theta_increment = 2 * PI / 89.0;
const phi_increment = 2 * PI / 314.0;

const screen_width = 50;
const screen_height = 50;

/// Render buffer
var r_buffer = [_]u8{' '} ** (screen_width * screen_height);
/// Depth buffer
var z_buffer = [_]f32{0} ** (screen_width * screen_height);

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // disable cursor and clear screen
    _ = try stdout.write("\x1B[?25l");
    _ = try stdout.write("\x1B[2J");

    // rotation in radians along x and z axis
    var rot_x: f32 = 0; // A
    var rot_z: f32 = 0; // B
    while (true) : ({
        rot_x += 0.1;
        rot_z += 0.1;
        if (rot_x > 2 * PI) rot_x = 0;
        if (rot_z > 2 * PI) rot_z = 0;
    }) {
        // Compute points on a circle, rotated around the y-axis
        // to form a torus "point cloud".
        var phi: f32 = 0;
        while (phi <= 2 * PI) : (phi += phi_increment) {
            var theta: f32 = 0;
            while (theta <= 2 * PI) : (theta += theta_increment) {
                // compute point on circle
                const circle_x = R2 + R1 * @cos(theta);
                const circle_y = R1 * @sin(theta);
                // implicitly z = 0

                // compute world-space point on torus using circle point,
                // "sweeping" the circle around the local y-axis by phi
                // and applying a rotation matrix.
                const torus_x = circle_x * (@cos(rot_z) * @cos(phi) + @sin(rot_x) * @sin(rot_z) * @sin(phi)) - circle_y * @cos(rot_x) * @sin(rot_z);
                const torus_y = circle_x * (@cos(phi) * @sin(rot_z) - @cos(rot_z) * @sin(rot_x) * @sin(phi)) + circle_y * @cos(rot_x) * @cos(rot_z);
                const torus_z = @cos(rot_x) * circle_x * @sin(phi) + circle_y * @sin(rot_x);

                // computing inverse of z avoids extra divisions and makes using the z-buffer easier
                const inverse_z = 1 / (K2 + torus_z);

                // project point from world-space into screen-space
                const scrn_x: usize = @intFromFloat(screen_width / 2 + (K1 * inverse_z * torus_x));
                const scrn_y: usize = @intFromFloat(screen_height / 2 - (K1 * inverse_z * torus_y)); // y is negated since in 3D +y is up, but in 2D -y is up

                // a mouthful, but correct.
                const luminance = @cos(phi) * @cos(theta) * @sin(rot_z) - @cos(rot_x) * @cos(theta) * @sin(phi) -
                    @sin(rot_x) * @sin(theta) + @cos(rot_z) * (@cos(rot_x) * @sin(theta) - @cos(theta) * @sin(rot_x) * @sin(phi));

                // luminance ranges from -sqrt(2) to +sqrt(2).
                // If it's < 0 the surface is pointing away from us, so it's not worth rendering.
                if (luminance > 0) {
                    const screen_idx = scrn_x + screen_width * scrn_y;
                    // test the z-buffer, a larger inverse_z means the point is closer to the camera.
                    if (inverse_z > z_buffer[screen_idx]) {
                        z_buffer[screen_idx] = inverse_z;
                        // r_buffer[screen_idx] = '0' + @as(u8, @intFromFloat(10 * inverse_z));

                        // multiplying luminance by 8 and casting to an integer puts it in the 0..11 range (8*sqrt(2) == 11.3).
                        r_buffer[screen_idx] = ".,-~:;=!*#$@"[@intFromFloat(luminance * 8)];
                    }
                }
            }
        }

        // reset cursor position
        _ = try stdout.write("\x1B[0;0H");

        // dump r_buffer to screen
        for (0..screen_height) |y| {
            try stdout.print("{s}\n", .{r_buffer[screen_width * y ..][0..screen_width]});
        }

        @memset(&r_buffer, ' '); // clear r_buffer
        @memset(&z_buffer, 0); // clear z_buffer
        std.time.sleep(33 * std.time.ns_per_ms);
    }

    // reset terminal
    _ = try stdout.write("\x1B[0m");
}

const std = @import("std");
