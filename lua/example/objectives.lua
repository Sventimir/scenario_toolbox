local Objectives = {}

function Objectives:wml(boss_name, boss_title, biome)
  return {
    team_name = "Bohaterowie",
    summary = string.format(
      "Odnajdź i pokonaj %s %s.",
      boss_title.accusative,
      boss_name.accusative
    ),
    wml.tag.objective({
        condition = "win",
        description = string.format(
          "Odnajdź ołtarz przywołania %s.",
          boss_title.genetive
        ),
    }),
    wml.tag.objective({
        condition = "win",
        description = "Zdobądź ofiarę konieczną do przywołania.",
    }),
    wml.tag.objective({
        condition = "win",
        description = string.format(
          "Pokonaj %s.",
          boss_title.accusative
        )
    }),
    wml.tag.note({
        description = string.format("Ołtarz znajduje się gdzieś wśród %s wyspy.", biome.genetive),
    }),
    wml.tag.note({
        description = string.format(
          "Wskazówkę co do wymaganej ofiary można znaleźć przy ołtarzu %s.",
          boss_title.genetive
        )
    }),
    wml.tag.note({
        description = "Specjalne lokacje zawierają opisy. Podejdź do nich dowoną jednostką i kliknij prawym przyciskiem aby się im przyjrzeć."
    }),
  }
end

return Objectives
