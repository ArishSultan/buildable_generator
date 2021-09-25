/// Support for doing something awesome.
///
/// More dartdocs go here.
library builder_generator;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/builder_generator_base.dart';

Builder generate(BuilderOptions options) =>
    SharedPartBuilder([BuildableGenerator()], 'builder_generator');
