import 'package:equatable/equatable.dart';

class ExportedFile extends Equatable {
  const ExportedFile({
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;

  @override
  List<Object?> get props => [filePath, fileName];
}
