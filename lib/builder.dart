library nexus.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/builder/gpu_shader_builder.dart';

/// The factory function that creates our builder.
/// It combines the PartBuilder with our custom generator.
Builder gpuShaderBuilder(BuilderOptions options) => PartBuilder(
      [GpuShaderGenerator()],
      '.g.dart',
      header: '// GENERATED CODE - DO NOT MODIFY BY HAND',
    );
