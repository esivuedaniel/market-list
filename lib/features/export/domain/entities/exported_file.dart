import 'package:equatable/equatable.dart';

class ExportedFile extends Equatable {
  const ExportedFile({
    required this.filePath,
    required this.fileName,
    this.listName,
    this.mimeType = 'application/pdf',
  });

  final String filePath;
  final String fileName;
  final String? listName;
  final String mimeType;

  @override
  List<Object?> get props => [filePath, fileName];
}
