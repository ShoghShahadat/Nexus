// import 'dart:async';
// import 'package:analyzer/dart/ast/ast.dart';
// import 'package:analyzer/dart/element/element.dart';
// import 'package:build/build.dart';
// import 'package:source_gen/source_gen.dart';
// import 'package:nexus/src/compute/gpu_system.dart';
// import 'wgsl_transpiler.dart';
// import 'package:analyzer/dart/analysis/results.dart'; // Import for ResolvedLibraryResult

// // --- FIX: Correctly targets the public annotation class ---
// class GpuShaderGenerator extends GeneratorForAnnotation<TranspileGpuSystem> {
//   @override
//   FutureOr<String> generateForAnnotatedElement(
//       Element element, ConstantReader annotation, BuildStep buildStep) async {
//     if (element is! ClassElement) {
//       throw InvalidGenerationSourceError(
//           '`@transpileGpuSystem` can only be used on classes.',
//           element: element);
//     }

//     final gpuLogicMethodElement = element.methods.firstWhere(
//       (method) => method.name == 'gpuLogic',
//       orElse: () => throw InvalidGenerationSourceError(
//           'Classes annotated with `@transpileGpuSystem` must have a `gpuLogic` method.',
//           element: element),
//     );

//     // --- FIX: Correctly resolve the AST node from the element using the new analyzer API ---
//     final session = gpuLogicMethodElement.session!;
//     final parsedLibrary = await session
//         .getResolvedLibraryByElement(gpuLogicMethodElement.library);

//     if (parsedLibrary is! ResolvedLibraryResult) {
//       throw InvalidGenerationSourceError(
//           'Could not resolve the library for the `gpuLogic` method.',
//           element: gpuLogicMethodElement);
//     }

//     // --- FINAL FIX: Call getElementDeclaration directly on the ResolvedLibraryResult object ---
//     final declaration = parsedLibrary
//         .getElementDeclaration(gpuLogicMethodElement)
//         ?.node as MethodDeclaration?;

//     if (declaration == null) {
//       throw InvalidGenerationSourceError(
//           'Could not resolve the AST for the `gpuLogic` method.',
//           element: gpuLogicMethodElement);
//     }

//     final transpiler = WgslTranspiler();
//     final shaderCode = transpiler.transpile(declaration);
//     final className = element.name;

//     return """
// // **************************************************************************
// // GpuShaderBuilder
// // **************************************************************************

// String _\$${className}WgslSourceCode() => r'''
// $shaderCode
// ''';
// """;
//   }
// }
