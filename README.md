A Mod for Factorio (https://www.factorio.com/)
======

Allows prospecting for ores.
This is achieved by producing ore maps  in a Geology lab.

The mod adds a Gui showing the prospection results, indicating direction and distance for the closest deposit (from the point where the map was used) found for each resource.
It also displays the direction and distance for failed prospections, so as to avoid useless prospecting (eg, whil still in range of a previous prospection).

Disclaimer : the mod should be mainly complete from a technical perspective, but not gameplay/balancing wise. Graphics and research/production costs are still placeholders

Credits : this mod reuses code fragments from ResourceMonitor (for the GUI and deposits handling)

Changes
- 1.2 now triggers chunks generation if required, and waits for chunks to be generated.
  * 0.12 compatible
- 1.1 initial version