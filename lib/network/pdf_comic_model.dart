import 'dart:io';
import 'package:pdfrx/pdfrx.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'base_comic.dart';

/// PDF漫画数据模型
class PdfComic extends BaseComic {
  @override
  final String id;

  @override
  final String title;

  @override
  String get subTitle => "";

  @override
  final String cover;

  @override
  final List<String> tags;

  @override
  final String description;

  final String pdfPath;

  final int pageCount;

  PdfComic({
    required this.id,
    required this.title,
    required this.cover,
    required this.pdfPath,
    required this.pageCount,
    this.tags = const [],
    this.description = "",
  });

  factory PdfComic.fromFile(File pdfFile) {
    final fileName = pdfFile.uri.pathSegments.last;
    final title = fileName.replaceAll('.pdf', '');
    final id = 'pdf_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}';

    return PdfComic(
      id: id,
      title: title,
      cover: '', // 封面路径将在导入时生成
      pdfPath: pdfFile.path,
      pageCount: 0, // 页数将在导入时计算
    );
  }
}

/// PDF下载项数据模型
class PdfDownloadedComic extends DownloadedItem {
  @override
  final String id;

  @override
  final String name;

  @override
  final String subTitle;

  final String pdfPath;

  final String coverPath;

  @override
  final List<String> eps;

  @override
  final List<int> downloadedEps;

  @override
  final double? comicSize;

  @override
  final DateTime? time;

  @override
  final List<String> tags;

  final int pageCount;

  PdfDownloadedComic({
    required this.id,
    required this.name,
    this.subTitle = "",
    required this.pdfPath,
    required this.coverPath,
    this.eps = const ["PDF"],
    this.downloadedEps = const [0],
    this.comicSize,
    this.time,
    this.tags = const [],
    this.pageCount = 0,
  });

  factory PdfDownloadedComic.fromJson(Map<String, dynamic> json) {
    return PdfDownloadedComic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subTitle: json['subTitle'] ?? "",
      pdfPath: json['pdfPath'] ?? '',
      coverPath: json['coverPath'] ?? '',
      comicSize: json['comicSize']?.toDouble(),
      time: json['time'] != null ? DateTime.tryParse(json['time']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      pageCount: json['pageCount'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subTitle': subTitle,
      'pdfPath': pdfPath,
      'coverPath': coverPath,
      'comicSize': comicSize,
      'time': time?.toIso8601String(),
      'tags': tags,
      'pageCount': pageCount,
      'type': DownloadType.pdf.index,
    };
  }

  @override
  set comicSize(double? value) {
    // PDF的comicSize在构造时确定,不需要setter
  }

  @override
  DownloadType get type => DownloadType.pdf;
}