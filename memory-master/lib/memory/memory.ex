defmodule Memory.Game do

  def new() do
    %{
      tileList: nextTileList(),
      clickNum: 0,
    }
  end

  def serverToClientState(sstate) do
    tiles = sstate.tileList;
    clicks = sstate.clickNum;
    %{
      matchedTilesIds: tiles|>Enum.filter(fn(mm)-> mm|>Map.get(:matched) end)
                          |>Enum.map(fn(mm)->mm|>Map.get(:id) end),
      selectedTilesIds: tiles|>Enum.filter(fn(mm)-> mm|>Map.get(:selected) end)
                          |>Enum.map(fn(mm)->mm|>Map.get(:id) end),
      score: calculateScore(tiles, clicks),
      clickNum: clicks,
      tileList: tiles,
    }
  end

  def calculateScore(tiles, clicks) do
      score = 100;
      numOfMatched = tiles|>Enum.filter(fn(mm)-> mm|>Map.get(:matched) end)|>Enum.count;
      if clicks>numOfTiles(tiles) do
        score * (numOfMatched/clicks);
      else
        score;
      end
  end

  def numOfTiles(tiles) do
    tiles|>Enum.count;
  end

  def onSelect(sstate, clickedTileIdx) do
    tiles = sstate.tileList;
    IO.puts Integer.to_string(clickedTileIdx);
    tiles = List.update_at(tiles, clickedTileIdx, &(Map.replace!(&1, :selected, true)));
    sstate|>Map.put(:tileList, tiles)|>Map.update!(:clickNum, &(&1+1));
  end


  def secondSelectMatch(sstate, selected1Idx, selected2Idx) do
    tiles = sstate.tileList;
    tiles = List.update_at(tiles, selected1Idx,
                  &(&1|>Map.replace!(:selected, false)
                      |>Map.replace!(:matched, true)));
    tiles = List.update_at(tiles, selected2Idx,
                  &(&1|>Map.replace!(:selected, false)
                      |>Map.replace!(:matched, true)));
    sstate|>Map.put(:tileList, tiles);
  end


  def secondSelectMiss(sstate, selected1Idx, selected2Idx) do
    tiles = sstate.tileList;
    tiles = List.update_at(tiles, selected1Idx,
                  &(&1|>Map.replace!(:selected, false)
                      |>Map.replace!(:matched, false)));
    tiles = List.update_at(tiles, selected2Idx,
                  &(&1|>Map.replace!(:selected, false)
                      |>Map.replace!(:matched, false)));
    sstate|>Map.put(:tileList, tiles);
  end


  def onTileSelected(sstate, tid) do

    tiles = sstate.tileList;
    selectedTiles = tiles|>Enum.filter(fn(tt) -> tt|>Map.get(:selected) end);
    clickedTileIdx =
      tiles|>Enum.find_index(fn(mm) -> tid == mm|>Map.get(:id) end);

    cond do
      selectedTiles|>Enum.count == 0 -> # no tile selected yet.
        onSelect(sstate, clickedTileIdx);
      selectedTiles|>Enum.count == 1 -> # one tile has been selected
        selectedTile = selectedTiles|>Enum.at(0);
        if tid == selectedTile|>Map.get(:id) do
          sstate;
        else
          onSelect(sstate, clickedTileIdx);
        end
      true ->
        IO.puts "more than 1 tile selected.";
        IO.puts selectedTiles|>Enum.count|>Integer.to_string;
        sstate;
    end
  end

  def onTimeout(sstate) do
    tiles = sstate.tileList;
    selecteds = tiles|>Enum.filter(fn(tt) -> true == tt|>Map.get(:selected) end);

    if selecteds|>Enum.count != 2 do
      sstate;
    else
      [selected1, selected2] =
        tiles|>Enum.filter(fn(tt) -> true == tt|>Map.get(:selected) end);
      selected1Idx = tiles|>Enum.find_index(fn(mm) ->
                      selected1|>Map.get(:id) == mm|>Map.get(:id) end);
      selected2Idx = tiles|>Enum.find_index(fn(mm) ->
                      selected2|>Map.get(:id) == mm|>Map.get(:id) end);
      cond do
        selected1|>Map.get(:letter) == selected2|>Map.get(:letter) ->
          secondSelectMatch(sstate, selected1Idx, selected2Idx);
        selected1|>Map.get(:letter) != selected2|>Map.get(:letter) ->
          secondSelectMiss(sstate, selected1Idx, selected2Idx);
        true ->
          IO.puts "erroooooor";
          sstate;
      end
    end
  end

  def nextTileList() do
    chars = "ABCDEFGH";
    Enum.join([chars, chars])
    |>String.graphemes
    |>Enum.shuffle
    |>Enum.map(fn(cc) ->
      %{letter: cc, selected: false, matched: false,}
    end)
    |>assignId(0,[]);
  end

  def assignId(lst, fstId, newLst) do
    if lst|>Enum.empty? do
      newLst;
    else
      fst = lst|>Enum.at(0);
      fst = fst|>Map.put(:id, fstId);
      fstLst = fst|>List.wrap;
      newLst = newLst ++ fstLst;
      lst = lst|>Enum.slice(1..-1);
      assignId(lst, fstId+1, newLst);
    end
  end

end
