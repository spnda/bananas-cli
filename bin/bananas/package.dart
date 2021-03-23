import 'dart:math';

import 'package:tint/tint.dart';

class Package {
  late String name;
  late String? description;
  late String? url;
  late String contentType;
  late String uniqueId;
  late List<Author>? authors;
  late List<Version>? versions;

  Package({required this.name, required this.description, required this.url, required this.contentType, required this.uniqueId, required this.authors, required this.versions});

  Package.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    url = json['url'];
    contentType = json['content-type'];
    uniqueId = json['unique-id'];
    if (json['authors'] != null) {
      authors = <Author>[];
      json['authors'].forEach((v) {
        authors?.add(Author.fromJson(v));
      });
    }
    if (json['versions'] != null) {
      versions = <Version>[];
      json['versions'].forEach((v) {
        versions?.add(Version.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['url'] = url;
    data['content-type'] = contentType;
    data['unique-id'] = uniqueId;
    if (authors != null) {
      data['authors'] = authors?.map((v) => v.toJson()).toList();
    }
    if (versions != null) {
      data['versions'] = versions?.map((v) => v.toJson()).toList();
    }
    return data;
  }

  String get latestVersion {
    if (versions == null) return '';
    return versions!.first.version;
  }

  String asInfoString({bool coloured = true}) {
    final buffer = StringBuffer();

    void write(String name, String value) {
      if (coloured) {
        buffer.writeln(name.gray() + ': ' + value);
      } else {
        buffer.writeln(name + value);
      }
    }

    // Basic metadata
    write('Name', name);
    if (description != null) write('Description', description!.replaceAll('\n', '').substring(0, min(100, description!.length)) + '...');
    if (url != null) write('URL', url!);
    write('ID', uniqueId);

    // Authors & Versions
    if (authors != null) {
      buffer.writeln('Authors'.gray() + ':');
      for (var author in authors!) {
        buffer.writeln('  - ${author.displayName}');
      }
    }
    if (versions != null) {
      buffer.writeln('Versions'.gray() + ':');
      for (var version in versions!) {
        buffer.writeln('  - ${version.version} (${DateTime.parse(version.uploadDate).toString()})');
      }
    }
    return buffer.toString();
  }

  @override
  String toString() => toJson().toString();
}

class Author {
  late String displayName;
  late String? openttd;

  Author({required this.displayName, required this.openttd});

  Author.fromJson(Map<String, dynamic> json) {
    displayName = json['display-name'];
    openttd = json['openttd'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['display-name'] = displayName;
    data['openttd'] = openttd;
    return data;
  }
}

class Version {
  late String version;
  late String license;
  late String uploadDate;
  late String md5sumPartial;
  late int filesize;
  late String availability;
  List<Compatibility>? compatibility;

  Version({required this.version, required this.license, required this.uploadDate, required this.md5sumPartial, required this.filesize, required this.availability, required this.compatibility});

  Version.fromJson(Map<String, dynamic> json) {
    version = json['version'];
    license = json['license'];
    uploadDate = json['upload-date'];
    md5sumPartial = json['md5sum-partial'];
    filesize = json['filesize'];
    availability = json['availability'];
    if (json['compatibility'] != null) {
      compatibility = <Compatibility>[];
      json['compatibility'].forEach((v) {
        compatibility?.add(Compatibility.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['version'] = version;
    data['license'] = license;
    data['upload-date'] = uploadDate;
    data['md5sum-partial'] = md5sumPartial;
    data['filesize'] = filesize;
    data['availability'] = availability;
    if (compatibility != null) {
      data['compatibility'] = compatibility?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Compatibility {
  late String name;
  late List<String> conditions;

  Compatibility({required this.name, required this.conditions});

  Compatibility.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    conditions = json['conditions'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['name'] = name;
    data['conditions'] = conditions;
    return data;
  }
}
