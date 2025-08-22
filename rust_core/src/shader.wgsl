// WGSL (WebGPU Shading Language) Code

struct SimParams {
    delta_time: f32,
    attractor_x: f32,
    attractor_y: f32,
    attractor_strength: f32,
};

struct Particle {
    pos: vec2<f32>,
    vel: vec2<f32>,
    age: f32,
    max_age: f32,
    initial_size: f32,
    _padding: f32,
};

@group(0) @binding(1)
var<uniform> params: SimParams;

@group(0) @binding(0)
var<storage, read_write> particles: array<Particle>;

// A simple pseudo-random function using hashing.
// یک تابع ساده شبه-تصادفی با استفاده از هش.
fn hash(n: f32) -> f32 {
    return fract(sin(n) * 43758.5453123);
}

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let index = global_id.x;
    
    let array_len = arrayLength(&particles);
    if (index >= array_len) {
        return;
    }

    var p = particles[index];

    // --- CRITICAL FIX: Complete respawn logic ---
    // If a particle's age is over its max_age, reset its position to the
    // attractor and give it a new random-like velocity to create a fountain effect.
    // --- اصلاح حیاتی: منطق کامل بازآفرینی ---
    // اگر عمر ذره‌ای از حداکثر عمرش بیشتر شود، موقعیت آن را به جاذب بازگردانده
    // و یک سرعت جدید و شبه-تصادفی برای ایجاد افکت فواره‌ای به آن می‌دهیم.
    if (p.age >= p.max_age) {
        // 1. Reset position to the attractor's current location
        p.pos = vec2<f32>(params.attractor_x, params.attractor_y);
        
        // 2. Generate a new pseudo-random velocity
        let seed = f32(index) + (params.delta_time * 1000.0);
        let angle = hash(seed) * 2.0 * 3.14159;
        let speed = 50.0 + hash(seed * 2.0) * 100.0; // Speed between 50 and 150
        p.vel = vec2<f32>(cos(angle) * speed, sin(angle) * speed);

        // 3. Reset age
        p.age = 0.0;
    }

    // --- Simulation Logic ---
    let attractor_pos = vec2<f32>(params.attractor_x, params.attractor_y);
    let dir = attractor_pos - p.pos;
    let dist_sq = dot(dir, dir);

    if (dist_sq > 1.0) {
        let dist = sqrt(dist_sq);
        let force = params.attractor_strength * 1000.0 / dist_sq;
        p.vel = p.vel + (dir / dist) * force * params.delta_time;
    }
    
    p.pos = p.pos + p.vel * params.delta_time;
    p.age = p.age + params.delta_time;

    particles[index] = p;
}
