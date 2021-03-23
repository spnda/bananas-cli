class NewPackageInfo {
  late String? name;
  late String? description;
  late String? url;
  late List<String> tags;
  late String? version;
  late String? license;
  late String? uploadDate;
  late String? md5sumPartial;
  late int? filesize;
  late String? availability;
  late List<Dependencies> dependencies;
  late List<Compatibility> compatibility;
  late String? contentType;
  late String? uniqueId;
  late List<Files> files;
  late List<String> warnings;
  late List<String> errors;
  late String? status;

  NewPackageInfo({required this.name, required this.description, required this.url, required this.tags, required this.version, required this.license, required this.uploadDate, required this.md5sumPartial, required this.filesize, required this.availability, required this.dependencies, required this.compatibility, required this.contentType, required this.uniqueId, required this.files, required this.warnings, required this.errors, required this.status});

  NewPackageInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    url = json['url'];
      tags = [];
    if (json['tags'] != null) {
      tags.addAll(json['tags'].cast<String>());
    }
    version = json['version'];
    license = json['license'];
    uploadDate = json['upload-date'];
    md5sumPartial = json['md5sum-partial'];
    filesize = json['filesize'];
    availability = json['availability'];
    dependencies = <Dependencies>[];
    if (json['dependencies'] != null) {
      json['dependencies'].forEach((v) {
        dependencies.add(Dependencies.fromJson(v));
      });
    }
    compatibility = <Compatibility>[];
    if (json['compatibility'] != null) {
      json['compatibility'].forEach((v) {
        compatibility.add(Compatibility.fromJson(v));
      });
    }
    contentType = json['content-type'];
    uniqueId = json['unique-id'];
    files = <Files>[];
    if (json['files'] != null) {
      json['files'].forEach((v) {
        files.add(Files.fromJson(v));
      });
    }
    warnings = json['warnings'].cast<String>();
    errors = json['errors'].cast<String>();
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    if (url != null) data['url'] = url;
    if (tags.isNotEmpty) {
      data['tags'] = tags;
    } else {
      data['tags'] = [];
    }
    if (version != null) data['version'] = version;
    if (license != null) data['license'] = license;
    if (uploadDate != null) data['upload-date'] = uploadDate;
    if (md5sumPartial != null) data['md5sum-partial'] = md5sumPartial;
    if (filesize != null) data['filesize'] = filesize;
    if (availability != null) data['availability'] = availability;
    if (dependencies.isNotEmpty) {
      data['dependencies'] = dependencies.map((v) => v.toJson()).toList();
    } else {
      data['dependencies'] = [];
    }
    if (compatibility.isNotEmpty) {
      data['compatibility'] = compatibility.map((v) => v.toJson()).toList();
    } else {
      data['compatibility'] = [];
    }
    // data['content-type'] = contentType;
    if (uniqueId != null) data['unique-id'] = uniqueId;
    if (files.isNotEmpty) {
      data['files'] = files.map((v) => v.toJson()).toList();
    }
    // data['warnings'] = warnings;
    // data['errors'] = errors;
    // data['status'] = status;
    return data;
  }
}

class Dependencies {
  late final String contentType;
  late final String uniqueId;
  late final String md5sumPartial;

  Dependencies({required this.contentType, required this.uniqueId, required this.md5sumPartial});

  Dependencies.fromJson(Map<String, dynamic> json) {
    contentType = json['content-type'];
    uniqueId = json['unique-id'];
    md5sumPartial = json['md5sum-partial'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['content-type'] = contentType;
    data['unique-id'] = uniqueId;
    data['md5sum-partial'] = md5sumPartial;
    return data;
  }
}

class Compatibility {
  late final String name;
  late final List<String> conditions;

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

class Files {
  late final String uuid;
  late final String filename;
  late final String filesize;
  late final List<String> errors;

  Files({required this.uuid, required this.filename, required this.filesize, required this.errors});

  Files.fromJson(Map<String, dynamic> json) {
    uuid = json['uuid'];
    filename = json['filename'];
    filesize = json['filesize'].toString();
    errors = json['errors'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['uuid'] = uuid;
    data['filename'] = filename;
    data['filesize'] = filesize;
    data['errors'] = errors;
    return data;
  }
}
