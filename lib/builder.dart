library nexus.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/builder/gpu_shader_builder.dart';
import 'src/builder/binary_builder.dart'; // Import the new builder

/// The factory function that creates the GPU shader builder.
Builder gpuShaderBuilder(BuilderOptions options) => PartBuilder(
      [GpuShaderGenerator()],
      '.g.dart',
      header: '// GENERATED CODE - DO NOT MODIFY BY HAND',
    );

/// The factory function that creates our new binary serialization builder.
Builder binaryBuilder(BuilderOptions options) => PartBuilder(
      [BinaryGenerator()],
      '.g.dart',
      header: '// GENERATED CODE - DO NOT MODIFY BY HAND',
    );
