use std::time::Instant;
use wgpu::util::DeviceExt;

// --- WASM specific imports ---
#[cfg(target_arch = "wasm32")]
use wasm_bindgen::prelude::*;
#[cfg(target_arch = "wasm32")]
use web_sys::console;

// --- Native FFI specific imports ---
#[cfg(not(target_arch = "wasm32"))]
use std::ffi::c_void;
#[cfg(not(target_arch = "wasm32"))]
use std::slice;
#[cfg(not(target_arch = "wasm32"))]
use std::sync::Once;
#[cfg(not(target_arch = "wasm32"))]
static INIT_LOGGER: Once = Once::new();


// A helper function to log messages to the browser console.
#[cfg(target_arch = "wasm32")]
fn console_log(s: &str) {
    console::log_1(&s.into());
}

#[repr(C)]
#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
struct SimParams {
    delta_time: f32,
    vortex_strength: f32,
}

pub struct GpuContext {
    device: wgpu::Device,
    queue: wgpu::Queue,
    compute_pipeline: wgpu::ComputePipeline,
    bind_group: wgpu::BindGroup,
    params_buffer: wgpu::Buffer,
    storage_buffer: wgpu::Buffer,
    particle_count: u32,
}

// --- WASM Bridge ---
#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
pub struct WasmGpuContext {
    internal: GpuContext,
}

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
impl WasmGpuContext {
    #[wasm_bindgen(js_name = runSimulation)]
    pub async fn run_simulation(&self, delta_time: f32) -> Result<f64, JsValue> {
        let micros = run_simulation_internal(&self.internal, delta_time).await;
        Ok(micros as f64)
    }
}

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
pub async fn init(initial_data: &[f32]) -> Result<WasmGpuContext, JsValue> {
    let context = create_gpu_context(initial_data)
        .await
        .map_err(|e| JsValue::from_str(&e))?;
    Ok(WasmGpuContext { internal: context })
}


// --- Core Logic (Shared between Native and WASM) ---

async fn create_gpu_context(initial_data: &[f32]) -> Result<GpuContext, String> {
    #[cfg(target_arch = "wasm32")]
    console_log("Rust (WASM): Starting GPU context creation...");
    let particle_count = (initial_data.len() / 4) as u32;

    let instance = wgpu::Instance::default();
    
    let adapter = instance.request_adapter(&wgpu::RequestAdapterOptions {
        power_preference: wgpu::PowerPreference::HighPerformance,
        force_fallback_adapter: false,
        compatible_surface: None,
    }).await.ok_or_else(|| "Rust Error: No suitable GPU adapter found.".to_string())?;
    
    #[cfg(target_arch = "wasm32")]
    console_log(&format!("Rust (WASM): Selected adapter: {:?}", adapter.get_info()));

    // --- FINAL FIX: Let the browser decide the limits for maximum compatibility ---
    let required_limits = if cfg!(target_arch = "wasm32") {
        wgpu::Limits::default() // Using default() lets the browser fill in the blanks.
    } else {
        wgpu::Limits::downlevel_defaults()
    };

    let (device, queue) = adapter.request_device(
        &wgpu::DeviceDescriptor {
            label: Some("Nexus Compute Device"),
            required_features: wgpu::Features::empty(),
            required_limits: required_limits,
        },
        None,
    ).await.map_err(|e| format!("Rust Error: Failed to create logical device. Error: {}", e))?;
    
    #[cfg(target_arch = "wasm32")]
    console_log("Rust (WASM): Logical device and queue created successfully.");

    let shader_code = include_str!("shader.wgsl");
    let shader_module = device.create_shader_module(wgpu::ShaderModuleDescriptor {
        label: Some("Simulation Shader"),
        source: wgpu::ShaderSource::Wgsl(shader_code.into()),
    });
    
    let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
        label: Some("Simulation Bind Group Layout"),
        entries: &[
            wgpu::BindGroupLayoutEntry { binding: 0, visibility: wgpu::ShaderStages::COMPUTE, ty: wgpu::BindingType::Buffer { ty: wgpu::BufferBindingType::Storage { read_only: false }, has_dynamic_offset: false, min_binding_size: None, }, count: None, },
            wgpu::BindGroupLayoutEntry { binding: 1, visibility: wgpu::ShaderStages::COMPUTE, ty: wgpu::BindingType::Buffer { ty: wgpu::BufferBindingType::Uniform, has_dynamic_offset: false, min_binding_size: None, }, count: None, },
        ],
    });

    let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
        label: Some("Simulation Pipeline Layout"),
        bind_group_layouts: &[&bind_group_layout],
        push_constant_ranges: &[],
    });

    let compute_pipeline = device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
        label: Some("Simulation Pipeline"),
        layout: Some(&pipeline_layout),
        module: &shader_module,
        entry_point: "main",
        compilation_options: Default::default(),
    });

    let storage_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
        label: Some("Storage Buffer"),
        contents: bytemuck::cast_slice(initial_data),
        usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_SRC | wgpu::BufferUsages::COPY_DST,
    });

    let params_buffer = device.create_buffer(&wgpu::BufferDescriptor {
        label: Some("Params Buffer"),
        size: std::mem::size_of::<SimParams>() as wgpu::BufferAddress,
        usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        mapped_at_creation: false,
    });

    let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
        label: Some("Simulation Bind Group"),
        layout: &bind_group_layout,
        entries: &[
            wgpu::BindGroupEntry { binding: 0, resource: storage_buffer.as_entire_binding(), },
            wgpu::BindGroupEntry { binding: 1, resource: params_buffer.as_entire_binding(), },
        ],
    });
    
    #[cfg(target_arch = "wasm32")]
    console_log("Rust (WASM): GPU context fully initialized.");
    Ok(GpuContext { device, queue, compute_pipeline, bind_group, params_buffer, storage_buffer, particle_count })
}

async fn run_simulation_internal(context: &GpuContext, delta_time: f32) -> u64 {
    let start_time = Instant::now();
    let params = SimParams { delta_time, vortex_strength: 5.0 };
    context.queue.write_buffer(&context.params_buffer, 0, bytemuck::cast_slice(&[params]));
    
    let mut encoder = context.device.create_command_encoder(&Default::default());
    {
        let mut compute_pass = encoder.begin_compute_pass(&Default::default());
        compute_pass.set_pipeline(&context.compute_pipeline);
        compute_pass.set_bind_group(0, &context.bind_group, &[]);
        let workgroup_size = 256;
        let workgroup_count = (context.particle_count + workgroup_size - 1) / workgroup_size;
        compute_pass.dispatch_workgroups(workgroup_count, 1, 1);
    }
    context.queue.submit(Some(encoder.finish()));
    context.device.poll(wgpu::Maintain::Wait);

    start_time.elapsed().as_micros() as u64
}

// --- Native FFI Bridge (Unchanged) ---
#[cfg(not(target_arch = "wasm32"))]
#[no_mangle]
pub extern "C" fn init_gpu(initial_data_ptr: *mut f32, len: usize) -> *mut c_void {
    INIT_LOGGER.call_once(|| {
        env_logger::init_from_env(env_logger::Env::default().default_filter_or("wgpu_core=warn,wgpu_hal=warn"));
    });
    
    let initial_data = unsafe { slice::from_raw_parts(initial_data_ptr, len) };
    match pollster::block_on(create_gpu_context(initial_data)) {
        Ok(context) => Box::into_raw(Box::new(context)) as *mut c_void,
        Err(e) => {
            eprintln!("Failed to create GPU context: {}", e);
            std::ptr::null_mut()
        }
    }
}

#[cfg(not(target_arch = "wasm32"))]
#[no_mangle]
pub extern "C" fn release_gpu(context_ptr: *mut c_void) {
    if !context_ptr.is_null() {
        unsafe { let _ = Box::from_raw(context_ptr as *mut GpuContext); }
    }
}

#[cfg(not(target_arch = "wasm32"))]
#[no_mangle]
pub extern "C" fn run_gpu_simulation(context_ptr: *mut c_void, delta_time: f32) -> u64 {
    if context_ptr.is_null() { return 0; }
    let context = unsafe { &*(context_ptr as *mut GpuContext) };
    pollster::block_on(run_simulation_internal(context, delta_time))
}
