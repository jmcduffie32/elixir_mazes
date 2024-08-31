defmodule Kruskal do
  defmodule State do
    defstruct grid: nil, neighbors: nil, cells_in_set: nil, set_for_cell: nil

    defp neighbors(grid, cell) do
      neighbors = []
      south_cell = Grid.south(grid, cell)
      east_cell = Grid.east(grid, cell)

      neighbors =
        if south_cell == nil do
          neighbors
        else
          [{cell, south_cell} | neighbors]
        end

      neighbors =
        if east_cell == nil do
          neighbors
        else
          [{cell, east_cell} | neighbors]
        end

      neighbors
    end

    def new(grid) do
      state = %State{grid: grid, neighbors: [], set_for_cell: %{}, cells_in_set: %{}}

      Enum.reduce(grid.grid, state, fn {_, cell}, state ->
        set = Enum.count(state.set_for_cell) + 1
        state = put_in(state.set_for_cell[cell], set)
        state = put_in(state.cells_in_set[set], [cell])
        state = put_in(state.neighbors, state.neighbors ++ neighbors(grid, cell))
        state
      end)
    end

    def can_merge(state, cell1, cell2) do
      set1 = Map.get(state.set_for_cell, cell1)
      set2 = Map.get(state.set_for_cell, cell2)
      set1 != set2
    end

    def merge(state, cell1, cell2) do
      winner = Map.get(state.set_for_cell, cell1)
      loser = Map.get(state.set_for_cell, cell2)
      losers = Map.get(state.cells_in_set, loser)

      state =
        Enum.reduce(losers, state, fn cell, state ->
          state = put_in(state.set_for_cell[cell], winner)
          state = update_in(state.cells_in_set[winner], fn winners -> [cell | winners] end)
          state
        end)

      state = put_in(state.grid, Grid.link(state.grid, cell1, cell2))
      state
    end
  end

  def on(grid) do
    state = State.new(grid)
    neighbors = Enum.shuffle(state.neighbors)

    Enum.reduce(neighbors, state, fn {cell1, cell2}, state ->
      if State.can_merge(state, cell1, cell2) do
        State.merge(state, cell1, cell2)
      else
        state
      end
    end)
  end
end
