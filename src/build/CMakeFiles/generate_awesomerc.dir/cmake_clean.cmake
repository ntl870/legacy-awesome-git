file(REMOVE_RECURSE
  "CMakeFiles/generate_awesomerc"
  "awesomerc.lua"
  "docs/05-awesomerc.md"
  "docs/06-appearance.md"
  "docs/common/client_rules_index.ldoc"
  "docs/common/notification_rules_index.ldoc"
  "docs/common/screen_rules_index.ldoc"
  "docs/common/tag_rules_index.ldoc"
  "script_files/rc.lua"
  "script_files/theme.lua"
)

# Per-language clean rules from dependency scanning.
foreach(lang )
  include(CMakeFiles/generate_awesomerc.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
