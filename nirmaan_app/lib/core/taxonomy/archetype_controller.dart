import 'package:flutter/material.dart';
import 'project_archetype.dart';

/// Central singleton controller for switching and querying active Project Archetype
class ArchetypeController extends ChangeNotifier {
  static final ArchetypeController instance = ArchetypeController._internal();
  ArchetypeController._internal();

  ProjectArchetype _current = ProjectArchetype.defaultArchetype;

  ProjectArchetype get current => _current;

  List<ProjectArchetype> get allArchetypes => ProjectArchetype.allArchetypes;

  void selectArchetype(String archetypeId) {
    if (_current.id != archetypeId) {
      _current = ProjectArchetype.getById(archetypeId);
      notifyListeners();
    }
  }

  void selectArchetypeDirect(ProjectArchetype archetype) {
    if (_current.id != archetype.id) {
      _current = archetype;
      notifyListeners();
    }
  }
}
