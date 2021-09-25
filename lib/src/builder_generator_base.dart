import 'package:builder/builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

class BuildableGenerator extends GeneratorForAnnotation<Buildable> {
  static String _toCap(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final classElement = element as ClassElement;
    final name = classElement.name;

    final buffer = StringBuffer();

    final errorsBuffer = StringBuffer();
    final fieldsBuffer = StringBuffer();
    final initFieldBuffer = StringBuffer();
    final buildFieldBuffer = StringBuffer();

    for (final field in classElement.fields) {
      final type = field.type.getDisplayString(withNullability: false);

      if (field.type.isDartCoreList) {
        final _type = (field.type as ParameterizedType)
            .typeArguments
            .first
            .getDisplayString(withNullability: false);

        fieldsBuffer.writeln('final $type _${field.name} = [];');
        fieldsBuffer.writeln('void addTo${_toCap(field.name)}($_type item) {');
        fieldsBuffer.writeln('  _${field.name}.add(item);');
        fieldsBuffer.writeln('}');
        fieldsBuffer.writeln(
            'void removeFrom${_toCap(field.name)}($_type item) {');
        fieldsBuffer.writeln('  _${field.name}.remove(item);');
        fieldsBuffer.writeln('}');
        fieldsBuffer
            .writeln('void removeFrom${_toCap(field.name)}At(int index) {');
        fieldsBuffer.writeln('  _${field.name}.removeAt(index);');
        fieldsBuffer.writeln('}');

        if (field.type.nullabilitySuffix == NullabilitySuffix.question) {
          buildFieldBuffer.writeln(
            '${field.name}: ${field.name}.isEmpty ? null : ${field.name},',
          );

          initFieldBuffer.writeln('if (instance.${field.name} != null) {');
          initFieldBuffer.writeln(
            '_${field.name}.addAll(instance.${field.name});',
          );
          initFieldBuffer.writeln('}');
        } else {
          buildFieldBuffer.writeln('${field.name}: _${field.name},');
          initFieldBuffer.writeln(
            '_${field.name}.addAll(instance.${field.name});',
          );
        }
      } else {
        fieldsBuffer.writeln('$type? ${field.name};');

        if (field.type.nullabilitySuffix == NullabilitySuffix.question) {
          buildFieldBuffer.writeln('${field.name}: ${field.name},');

          initFieldBuffer.writeln('${field.name} = instance.${field.name};');
        } else {
          errorsBuffer.writeln('if (${field.name} == null) {');
          errorsBuffer.writeln("throw '`${field.name}` must not be null';");
          errorsBuffer.writeln('}');
          buildFieldBuffer.writeln('${field.name}: ${field.name}!,');
          initFieldBuffer.writeln('${field.name} = instance.${field.name};');
        }
      }
    }

    buffer.writeln('class _${name}Builder {');
    buffer.writeln('  _${name}Builder([$name? instance]) {');
    buffer.writeln('   if (instance != null) {');
    buffer.writeln(initFieldBuffer);
    buffer.writeln('   }');
    buffer.writeln(' }');
    buffer.writeln(fieldsBuffer);
    buffer.writeln('  $name build() {');
    buffer.writeln(errorsBuffer);
    buffer.writeln('    return $name(');
    buffer.writeln(buildFieldBuffer);
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }
}
