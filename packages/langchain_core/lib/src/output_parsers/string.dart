import '../../llms.dart';
import '../chat_models/types.dart';
import '../documents/document.dart';
import '../language_models/types.dart';
import '../runnables/runnable.dart';
import 'base.dart';
import 'types.dart';

/// {@template string_output_parser}
/// Output parser that returns the output of the previous [Runnable] as a
/// `String`.
///
/// - [ParserInput] - The type of the input to the parser.
///
/// If the input is:
/// - `null`, the parser returns an empty String.
/// - A [LLMResult], the parser returns the output String.
/// - A [ChatResult], the parser returns the content of the output message as a String.
/// - A [ChatMessage], the parser returns the content of the message as a String.
/// - A [Document], the parser returns the page content as a String.
/// - Anything else, the parser returns the String representation of the input.
///
/// Example:
/// ```dart
/// final model = ChatOpenAI(apiKey: openAiApiKey);
/// final promptTemplate = ChatPromptTemplate.fromTemplate(
///   'Tell me a joke about {topic}',
/// );
/// final chain = promptTemplate | model | StringOutputParser();
/// final res = await chain.invoke({'topic': 'bears'});
/// print(res);
/// // Why don't bears wear shoes? Because they have bear feet!
/// ```
/// {@endtemplate}
class StringOutputParser<ParserInput extends Object?>
    extends BaseOutputParser<ParserInput, OutputParserOptions, String> {
  /// {@macro string_output_parser}
  const StringOutputParser({
    this.reduceOutputStream = false,
  }) : super(defaultOptions: const OutputParserOptions());

  /// When invoking this parser with [Runnable.stream], every item from the
  /// input stream will be parsed and emitted by default.
  ///
  /// If [reduceOutputStream] is set to `true`, the parser will reduce the
  /// output stream into a single String and emit it as a single item.
  ///
  /// Visual example:
  /// - reduceOutputStream = false
  /// 'A', 'B', 'C' -> 'A', 'B', 'C'
  /// - reduceOutputStream = true
  /// 'A', 'B', 'C' -> 'ABC'
  final bool reduceOutputStream;

  @override
  Future<String> invoke(
    final ParserInput input, {
    final OutputParserOptions? options,
  }) {
    return Future.value(_parse(input));
  }

  @override
  Stream<String> streamFromInputStream(
    final Stream<ParserInput> inputStream, {
    final OutputParserOptions? options,
  }) async* {
    if (reduceOutputStream) {
      yield await inputStream.map(_parse).reduce((final a, final b) => '$a$b');
    } else {
      yield* inputStream.map(_parse);
    }
  }

  String _parse(final ParserInput input) {
    final output = switch (input) {
      null => '',
      final LanguageModelResult res => res.outputAsString,
      final ChatMessage res => res.contentAsString,
      final Document res => res.pageContent,
      _ => input.toString(),
    };
    return output;
  }
}
