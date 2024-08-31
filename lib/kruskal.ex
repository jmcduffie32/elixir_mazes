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
        state = update_in(state.neighbors, &Enum.concat(&1, neighbors(grid, cell)))
        state
      end)
    end

    def can_merge(state, cell1, cell2) do
      set1 = get_in(state.set_for_cell[cell1])
      set2 = get_in(state.set_for_cell[cell2])
      set1 != set2
    end

    def merge(state, cell1, cell2) do
      winner = get_in(state.set_for_cell[cell1])
      loser = get_in(state.set_for_cell[cell2])
      losers = get_in(state.cells_in_set[loser]) || [cell2]

      state =
        Enum.reduce(losers, state, fn cell, state ->
          state = put_in(state.set_for_cell[cell], winner)
          state = update_in(state.cells_in_set[winner], fn winners -> [cell | winners] end)
          state
        end)

      state = update_in(state.grid, &Grid.link(&1, cell1, cell2))
      state
    end

    def add_crossing(state, cell) do
      west_cell = Grid.west(state.grid, cell)
      east_cell = Grid.east(state.grid, cell)
      north_cell = Grid.north(state.grid, cell)
      south_cell = Grid.south(state.grid, cell)

      if Grid.has_links?(state.grid, cell) || !can_merge(state, east_cell, west_cell) ||
           !can_merge(state, north_cell, south_cell) do
        state
      else
        state = %{
          state
          | neighbors:
              Enum.filter(state.neighbors, fn {left, right} -> left != cell && right != cell end)
        }

        under_cell = %{cell | over: false}
        state = update_in(state.grid.under_cells, &Map.put(&1, {under_cell.row, under_cell.col}, under_cell)
)

        if :rand.uniform() < 0.5 do
          state
          |> merge(west_cell, cell)
          |> merge(cell, east_cell)
          |> merge(north_cell, under_cell)
          |> merge(south_cell, under_cell)
        else
          state
          |> merge(north_cell, cell)
          |> merge(cell, south_cell)
          |> merge(east_cell, under_cell)
          |> merge(west_cell, under_cell)
        end
      end
    end
  end

  def on(state) do
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
