// A struct for our particle data
struct Particle {
    pos: vec2<f32>,
    vel: vec2<f32>,
};

// A struct for simulation parameters
struct SimParams {
    delta_time: f32,
    vortex_strength: f32,
};

// The main data buffer, now read_write
@group(0) @binding(0)
var<storage, read_write> particles: array<Particle>;

// The uniform buffer for parameters
@group(0) @binding(1)
var<uniform> params: SimParams;

// The main compute shader function
@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let index = global_id.x;
    let array_len = arrayLength(&particles);
    if (index >= array_len) {
        return;
    }

    var p = particles[index];

    // --- MORE COMPLEX CALCULATION ---
    // Calculate distance from center (0,0)
    let dist = length(p.pos);

    if (dist > 0.01) { // Avoid division by zero at the center
        // Calculate direction perpendicular to the vector from the center
        let perp_dir = vec2<f32>(-p.pos.y, p.pos.x) / dist;
        
        // Add a vortex force that pulls particles in a circle
        // The force is stronger near the center
        let vortex_force = perp_dir * (params.vortex_strength / (dist + 0.1));
        p.vel = p.vel + vortex_force * params.delta_time;
    }

    // Add a sine wave to the velocity for more complex movement
    p.vel.x = p.vel.x + sin(p.pos.y * 10.0) * 0.1 * params.delta_time;
    p.vel.y = p.vel.y + cos(p.pos.x * 10.0) * 0.1 * params.delta_time;

    // Apply gravity
    p.vel.y = p.vel.y - 1.0 * params.delta_time;
    
    // Update position
    p.pos = p.pos + p.vel * params.delta_time;

    // Simple bounce off screen edges
    if (p.pos.x < -1.0 || p.pos.x > 1.0) {
        p.pos.x = clamp(p.pos.x, -1.0, 1.0);
        p.vel.x = -p.vel.x * 0.8;
    }
    if (p.pos.y < -1.0 || p.pos.y > 1.0) {
        p.pos.y = clamp(p.pos.y, -1.0, 1.0);
        p.vel.y = -p.vel.y * 0.8;
    }

    // Write the updated data back to the buffer
    particles[index] = p;
}
