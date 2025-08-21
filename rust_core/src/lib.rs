use std::ffi::c_void;
use std::slice;
use std::sync::Once;
use std::time::Instant;
use wgpu::util::DeviceExt;

static INIT_LOGGER: Once = Once::new();

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
    staging_buffer: wgpu::Buffer,
    storage_buffer: wgpu::Buffer,
    particle_count: u32,
}

#[no_mangle]
pub extern "C" fn init_gpu(initial_data_ptr: *mut f32, len: usize) -> *mut c_void {
    INIT_LOGGER.call_once(|| {
        env_logger::init_from_env(env_logger::Env::default().default_filter_or("wgpu_core=warn,wgpu_hal=warn"));
    });
    
    let initial_data = unsafe { slice::from_raw_parts(initial_data_ptr, len) };
    let particle_count = (len / 4) as u32;

    let context = pollster::block_on(async {
        let instance = wgpu::Instance::default();
        let adapter = instance.request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::HighPerformance,
            ..Default::default()
        }).await.unwrap();
        
        log::info!("Using adapter: {}", adapter.get_info().name);
        let (device, queue) = adapter.request_device(&Default::default(), None).await.unwrap();

        let shader_code = include_str!("shader.wgsl");
        let shader_module = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Simulation Shader"),
            source: wgpu::ShaderSource::Wgsl(shader_code.into()),
        });
        
        let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("Simulation Bind Group Layout"),
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::COMPUTE,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Storage { read_only: false },
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::COMPUTE,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
            ],
        });

        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Simulation Pipeline Layout"),
            bind_group_layouts: &[&bind_group_layout],
            ..Default::default()
        });

        let compute_pipeline = device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: Some("Simulation Pipeline"),
            layout: Some(&pipeline_layout),
            module: &shader_module,
            entry_point: "main",
        });

        let buffer_size = (len * std::mem::size_of::<f32>()) as wgpu::BufferAddress;

        let storage_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Storage Buffer"),
            contents: bytemuck::cast_slice(initial_data),
            usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_SRC | wgpu::BufferUsages::COPY_DST,
        });

        let staging_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("Staging Buffer"),
            size: buffer_size,
            usage: wgpu::BufferUsages::MAP_READ | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
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
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: storage_buffer.as_entire_binding(),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: params_buffer.as_entire_binding(),
                },
            ],
        });

        GpuContext {
            device,
            queue,
            compute_pipeline,
            bind_group,
            params_buffer,
            staging_buffer,
            storage_buffer,
            particle_count,
        }
    });

    Box::into_raw(Box::new(context)) as *mut c_void
}

#[no_mangle]
pub extern "C" fn release_gpu(context_ptr: *mut c_void) {
    if !context_ptr.is_null() {
        unsafe { let _ = Box::from_raw(context_ptr as *mut GpuContext); }
        log::info!("GPU Context released.");
    }
}

async fn run_simulation(context: &GpuContext, delta_time: f32) -> u64 {
    let start_time = Instant::now();
    let device = &context.device;
    let queue = &context.queue;

    let params = SimParams { delta_time, vortex_strength: 5.0 };
    queue.write_buffer(
        &context.params_buffer,
        0,
        bytemuck::cast_slice(&[params]),
    );
    
    let mut encoder = device.create_command_encoder(&Default::default());
    {
        let mut compute_pass = encoder.begin_compute_pass(&Default::default());
        compute_pass.set_pipeline(&context.compute_pipeline);
        compute_pass.set_bind_group(0, &context.bind_group, &[]);
        
        let workgroup_size = 256;
        let workgroup_count = (context.particle_count + workgroup_size - 1) / workgroup_size;
        compute_pass.dispatch_workgroups(workgroup_count, 1, 1);
    }
    queue.submit(Some(encoder.finish()));
    
    device.poll(wgpu::Maintain::Wait);

    start_time.elapsed().as_micros() as u64
}

#[no_mangle]
pub extern "C" fn run_gpu_simulation(context_ptr: *mut c_void, delta_time: f32) -> u64 {
    if context_ptr.is_null() { return 0; }
    let context = unsafe { &*(context_ptr as *mut GpuContext) };
    pollster::block_on(run_simulation(context, delta_time))
}
