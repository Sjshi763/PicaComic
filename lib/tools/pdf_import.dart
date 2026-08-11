import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/pdf_comic_model.dart';
import 'package:pica_comic/tools/io_tools.dart';

/// PDF导入工具类
class PdfImportTool {
  /// 选择PDF文件
  static Future<String?> selectPdfFile() async {
    try {
      if (App.isMobile) {
        final params = const OpenFileDialogParams();
        final filePath = await FlutterFileDialog.pickFile(params: params);
        if (filePath != null && filePath.toLowerCase().endsWith('.pdf')) {
          return filePath;
        }
        return null;
      } else {
        const typeGroup = XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
        );
        final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
        return file?.path;
      }
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "PdfImport", "Failed to select PDF: $e\n$s");
      return null;
    }
  }

  /// 导入PDF文件(复制到下载目录并返回信息)
  static Future<PdfDownloadedComic?> importPdf(String pdfPath, String downloadPath) async {
    try {
      final sourceFile = File(pdfPath);
      if (!await sourceFile.exists()) {
        LogManager.addLog(LogLevel.error, "PdfImport", "PDF file not found: $pdfPath");
        return null;
      }

      // 生成唯一ID
      final fileName = sourceFile.uri.pathSegments.last;
      final title = fileName.replaceAll('.pdf', '');
      final id = 'pdf_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}';

      // 创建目标目录
      final targetDir = '$downloadPath/$id';
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final targetPath = '$targetDir/$sanitizedFileName';
      await Directory(targetDir).create(recursive: true);

      // 复制PDF文件
      await sourceFile.copy(targetPath);

      // 打开PDF获取信息
      final document = await PdfDocument.openFile(targetPath);
      final pageCount = document.pages.length;

      // 渲染第一页作为封面
      final coverPath = '$targetDir/cover.jpg';
      await _renderCover(document, coverPath);

      // 获取文件大小
      final fileSize = await sourceFile.length();
      final fileSizeMB = fileSize / 1024 / 1024;

      final comic = PdfDownloadedComic(
        id: id,
        name: title,
        pdfPath: targetPath,
        coverPath: coverPath,
        pageCount: pageCount,
        comicSize: fileSizeMB,
        time: DateTime.now(),
      );

      LogManager.addLog(LogLevel.info, "PdfImport", "Successfully imported PDF: $title");
      return comic;
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "PdfImport", "Failed to import PDF: $e\n$s");
      return null;
    }
  }

  /// 渲染PDF封面(第一页)
  static Future<void> _renderCover(PdfDocument document, String coverPath) async {
    try {
      final firstPage = document.pages[0];
      final pageImage = await firstPage.render(
        width: firstPage.width * 0.5,
        height: firstPage.height * 0.5,
      );

      if (pageImage != null) {
        final imageBytes = pageImage.bytes;
        if (imageBytes != null) {
          final coverFile = File(coverPath);
          await coverFile.writeAsBytes(imageBytes);
        }
      }
    } catch (e, s) {
      LogManager.addLog(LogLevel.warning, "PdfImport", "Failed to render cover: $e\n$s");
    }
  }
}