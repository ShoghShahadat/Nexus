// WGSL (WebGPU Shading Language) Code

// This struct MUST EXACTLY match the `SimParams` struct in `lib.rs`
// این ساختار باید دقیقاً با ساختار `SimParams` در `lib.rs` مطابقت داشته باشد
struct SimParams {
    delta_time: f32,
    attractor_x: f32,
    attractor_y: f32,
    attractor_strength: f32,
};

// This struct defines the layout of a single particle in the storage buffer.
// It MUST EXACTLY match the data layout created by `flattenData` in Dart (8 floats).
// vec2<f32> = 2 floats. So this struct is 2 + 2 + 1 + 1 + 1 + 1 = 8 floats total.
// این ساختار چیدمان یک ذره را در بافر ذخیره‌سازی تعریف می‌کند.
// باید دقیقاً با چیدمان داده ایجاد شده توسط `flattenData` در Dart (۸ فلوت) مطابقت داشته باشد.
struct Particle {
    pos: vec2<f32>,
    vel: vec2<f32>,
    age: f32,
    max_age: f32,
    initial_size: f32,
    _padding: f32, // Padding to ensure data alignment
};

// Binding for the uniform parameters
@group(0) @binding(1)
var<uniform> params: SimParams;

// Binding for the main particle data storage buffer
@group(0) @binding(0)
var<storage, read_write> particles: array<Particle>;

// The main entry point for the compute shader
@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let index = global_id.x;
    
    // Prevent out-of-bounds access
    // This is a safeguard; particle_count should be handled correctly by the dispatcher
    let array_len = arrayLength(&particles);
    if (index >= array_len) {
        return;
    }

    var p = particles[index];

    // --- Simulation Logic ---

    // 1. Attractor Force Calculation
    let attractor_pos = vec2<f32>(params.attractor_x, params.attractor_y);
    let dir = attractor_pos - p.pos;
    let dist_sq = dot(dir, dir);

    // Apply force only if not too close, to prevent division by zero and extreme velocities
    if (dist_sq > 1.0) {
        let dist = sqrt(dist_sq);
        // Using a simplified gravity model
        let force = params.attractor_strength * 1000.0 / dist_sq;
        p.vel = p.vel + (dir / dist) * force * params.delta_time;
    }
    
    // 2. Apply Velocity and Age
    p.pos = p.pos + p.vel * params.delta_time;
    p.age = p.age + params.delta_time;

    // 3. Reset particle if its age exceeds its max_age
    // This creates a continuous fountain effect from the spawn point
    if (p.age >= p.max_age) {
        // For this example, we just reset the age. A more complex system
        // might reset position and velocity as well.
        p.age = 0.0;
    }

    // Write the updated particle data back to the storage buffer
    particles[index] = p;
}
