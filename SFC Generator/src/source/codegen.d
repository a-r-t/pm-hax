import std.conv, std.algorithm, std.string, std.typecons, std.array, std.stdio;

alias ComboEntry = Tuple!(uint, "buttons", string,       "songListName");
alias StageEntry = Tuple!(uint, "id",      ComboEntry[], "combos",      string, "name");
alias SongList   = Tuple!(uint, "startID", uint,         "numSongs",    string, "name");
alias Options    = Tuple!(uint, "baseSongID");

static immutable BUTTON_STRINGS = ["W", "E", "S", "N", "Z", "R", "L", "", "A", "B", "X", "Y", "St"];

string generateCode(StageEntry[] entries, SongList[] songLists, Options options) {
  auto builder = appender!string;

  builder.put(import("codestart.txt"));

  auto stageLabels = entries.map!(x => format("stage_%x", x.id)).array ~ "end";
  uint lastStage = -1;

  string[string] songListLabels;
  songLists.each!(x => songListLabels[x.name] = format("songlist_%x_%d", x.startID, x.numSongs));

  foreach (i, stage; entries) {
    auto comboLabels = stage.combos.map!(x => getComboLabel(stage.id, x.buttons)).array;

    builder.put("\n");
    builder.put(stageLabels[i]);
    builder.put(":\n"); 

    builder.put(format("  cmpwi r27, 0x%x\n", stage.id));
    builder.put(format("  bne+ %s\n\n", stageLabels[i+1]));

    string defaultTag;

    foreach (j, combo; stage.combos) {
      if (combo.buttons == 0) {
        defaultTag = songListLabels[combo.songListName];
        continue;
      }

      builder.put("  ");
      builder.put(comboLabels[j]);
      builder.put(":\n");

      builder.put(format("    cmpwi r12, 0x%x\n", combo.buttons));
      //writeln(combo.songListName);
      builder.put(format("    beq- %s\n\n", songListLabels[combo.songListName]));
    }

    if (defaultTag != "") {
      builder.put(format("  b %s\n", defaultTag));
    }

    lastStage = stage.id;
  }

  builder.put("\n  b last\n\n");

  foreach (list; songLists) {
    builder.put(songListLabels[list.name]);
    builder.put(":\n");
    builder.put(format("    li r7, %d\n", list.numSongs));

    if (list.startID > 0x7FFF) {
      if (list.startID == 0xFFFF) {
        builder.put("    li r16, 0x7FFF\n");
        builder.put("    addi r16, r16, 1\n");
      }
      else {
        builder.put(format("    li r16, 0x%x\n", list.startID-0x7FFF));
      }

      builder.put("    b add_base\n\n");
    }
    else {
      builder.put(format("    li r16, 0x%x\n", list.startID));
      builder.put("    b last\n\n");
    }
  }

  builder.put(import("codeend.txt"));

  return builder.data;
}

private string getComboLabel(uint stageID, uint combo) {
  auto builder = appender!string;
  builder.put(format("stage_%x_", stageID));

  if (combo == 0) {
    builder.put("default");
  }
  else {
    foreach (i; 0..13) {
      if ((1 << i) & combo) {
        builder.put(BUTTON_STRINGS[i]);
      }
    }
  }

  return builder.data;
}
