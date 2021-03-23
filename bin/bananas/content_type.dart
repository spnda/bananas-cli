enum BananasContentType {
  ai,
  ai_library,
  base_graphics,
  base_music,
  base_sounds,
  game_script,
  game_script_library,
  heightmap,
  newgrf,
  scenario,
}

extension BananasContentTypeExt on BananasContentType {
  String get() {
    return getHumanReadable().toLowerCase();
  }

  String getHumanReadable() {
    switch (this) {
      case BananasContentType.ai:
        return 'AI';
      case BananasContentType.ai_library:
        return 'AI-Library';
      case BananasContentType.base_graphics:
        return 'Base-Graphics';
      case BananasContentType.base_music:
        return 'Base-Music';
      case BananasContentType.base_sounds:
        return 'Base-Sounds';
      case BananasContentType.game_script:
        return 'Game-Script';
      case BananasContentType.game_script_library:
        return 'Game-Script-Library';
      case BananasContentType.heightmap:
        return 'Heightmap';
      case BananasContentType.newgrf:
        return 'NewGRF';
      case BananasContentType.scenario:
        return 'Scenario';
      default:
        return '';
    }
  }

  static BananasContentType fromString(String str) {
    return BananasContentType.values.where((t) => t.get().toLowerCase() == str.toLowerCase()).first;
  }
}
