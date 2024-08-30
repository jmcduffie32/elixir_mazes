defmodule Grid do
  defstruct type: :square, rows: 0, cols: 0, grid: %{}, links: %{}, weave: false, under_cells: %{}

  def new(rows, cols, type \\ :square, weave \\ false) do
    %Grid{type: type, rows: rows, cols: cols, grid: %{}, links: %{}, weave: weave}
  end

  defp polar_col_count(grid, row) do
    grid.cols * 2 ** div(row, 2)
  end

  def prepare_grid(%Grid{type: :polar} = grid) do
    Map.put(
      grid,
      :grid,
      for(
        row <- 0..(grid.rows - 1),
        col <- 0..(grid.cols * 2 ** div(row, 2) - 1),
        into: %{},
        do: {{row, col}, Cell.new(row, col)}
      )
    )
  end

  def prepare_grid(%Grid{} = grid) do
    Map.put(
      grid,
      :grid,
      for(
        row <- 0..(grid.rows - 1),
        col <- 0..(grid.cols - 1),
        into: %{},
        do: {{row, col}, Cell.new(row, col)}
      )
    )
  end

  def neighbors(%Grid{type: :polar} = grid, %{row: row, col: col}) do
    potential_neighbors =
      if rem(row, 2) == 0 do
        [
          {row - 1, div(col, 2)},
          {row + 1, col},
          {row,
           if col + 1 >= polar_col_count(grid, row) do
             0
           else
             col + 1
           end},
          {row,
           if col - 1 < 0 do
             polar_col_count(grid, row) - 1
           else
             col - 1
           end}
        ]
      else
        [
          {row - 1, col},
          {row + 1, col * 2},
          {row + 1, col * 2 + 1},
          {row,
           if col + 1 >= polar_col_count(grid, row) do
             0
           else
             col + 1
           end},
          {row,
           if col - 1 < 0 do
             polar_col_count(grid, row) - 1
           else
             col - 1
           end}
        ]
      end

    # filter potential neighbors to only include those that are within the grid
    Enum.filter(potential_neighbors, fn {r, c} -> Map.get(grid.grid, {r, c}) end)
  end

  def neighbors(%Grid{weave: true} = grid, %{row: row, col: col} = cell) do
    potential_neighbors =
      neighbors(%{grid | weave: false}, cell) ++
        [
          if can_tunnel_south?(grid, cell) do
            {row + 2, col}
          else
            nil
          end,
          if can_tunnel_north?(grid, cell) do
            {row - 2, col}
          else
            nil
          end,
          if can_tunnel_east?(grid, cell) do
            {row, col + 2}
          else
            nil
          end,
          if can_tunnel_west?(grid, cell) do
            {row, col - 2}
          else
            nil
          end
        ]

    # filter potential neighbors to only include those that are within the grid
    potential_neighbors
    |> Enum.filter(fn v -> v end)
    |> Enum.filter(fn {r, c} -> Map.get(grid.grid, {r, c}) end)
  end

  def neighbors(grid, %{row: row, col: col}) do
    potential_neighbors = [
      {row - 1, col},
      {row, col + 1},
      {row + 1, col},
      {row, col - 1}
    ]

    # filter potential neighbors to only include those that are within the grid
    Enum.filter(potential_neighbors, fn {r, c} -> Map.get(grid.grid, {r, c}) end)
  end

  def north(grid, %{row: row, col: col}) do
    Map.get(grid.grid, {row - 1, col})
  end

  def south(grid, %{row: row, col: col}) do
    Map.get(grid.grid, {row + 1, col})
  end

  def east(grid, %{row: row, col: col}) do
    Map.get(grid.grid, {row, col + 1})
  end

  def west(grid, %{row: row, col: col}) do
    Map.get(grid.grid, {row, col - 1})
  end

  def north_under(grid, %{row: row, col: col}) do
    Map.get(grid.under_cells, {row - 1, col})
  end

  def south_under(grid, %{row: row, col: col}) do
    Map.get(grid.under_cells, {row + 1, col})
  end

  def east_under(grid, %{row: row, col: col}) do
    Map.get(grid.under_cells, {row, col + 1})
  end

  def west_under(grid, %{row: row, col: col}) do
    Map.get(grid.under_cells, {row, col - 1})
  end

  # polar grid directions
  def inward(grid, %{row: row, col: col}) do
    if rem(row, 2) == 0 do
      Map.get(
        grid.grid,
        {row - 1, div(col, 2)}
      )
    else
      Map.get(
        grid.grid,
        {row - 1, col}
      )
    end
  end

  def clockwise(grid, %{row: row, col: col}) do
    if col - 1 < 0 do
      Map.get(grid.grid, {row, polar_col_count(grid, row) - 1})
    else
      Map.get(grid.grid, {row, col - 1})
    end
  end

  def counter_clockwise(grid, %{row: row, col: col}) do
    if col + 1 >= polar_col_count(grid, row) do
      Map.get(grid.grid, {row, 0})
    else
      Map.get(grid.grid, {row, col + 1})
    end
  end

  def random_cell(grid) do
    row = :rand.uniform(grid.rows) - 1
    col = :rand.uniform(grid.cols) - 1
    Map.get(grid.grid, {row, col})
  end

  def link(%Grid{weave: true} = grid, cell1, cell2) do
    cell_to_go_under =
      cond do
        north(grid, cell1) == south(grid, cell2) && north(grid, cell1) != nil ->
          north(grid, cell1)

        south(grid, cell1) == north(grid, cell2) && south(grid, cell1) != nil ->
          south(grid, cell1)

        east(grid, cell1) == west(grid, cell2) && east(grid, cell1) != nil ->
          east(grid, cell1)

        west(grid, cell1) == east(grid, cell2) && west(grid, cell1) != nil ->
          west(grid, cell1)

        true ->
          nil
      end

    if cell_to_go_under do
      new_cell = %Cell{
        row: cell_to_go_under.row,
        col: cell_to_go_under.col,
        over: false
      }

      new_undercells =
        Map.put(grid.under_cells, {new_cell.row, new_cell.col}, new_cell)

      grid = %{grid | under_cells: new_undercells}

      links =
        grid.links
        |> put_in([{cell1, new_cell}], true)
        |> put_in([{new_cell, cell1}], true)
        |> put_in([{cell2, new_cell}], true)
        |> put_in([{new_cell, cell2}], true)

      %{grid | links: links}
    else
      links =
        grid.links
        |> put_in([{cell1, cell2}], true)
        |> put_in([{cell2, cell1}], true)

      %{grid | links: links}
    end
  end

  def link(grid, cell1, cell2) do
    links =
      grid.links
      |> put_in([{cell1, cell2}], true)
      |> put_in([{cell2, cell1}], true)

    %{grid | links: links}
  end

  defp draw_straight_wall(x1, y1, x2, y2) do
    """
    <line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="black" stroke-width="1"/>
    """
  end

  defp draw_straight_wall(grid, cell, x1, y1, x2, y2, dir_fn) do
    if Map.get(grid.links, {cell, dir_fn.(grid, cell)}) do
      ""
    else
      """
      <line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="black" stroke-width="1"/>
      """
    end
  end

  defp draw_arc_wall(grid, cell, x1, y1, r, x2, y2, dir_fn) do
    if Map.get(grid.links, {cell, dir_fn.(grid, cell)}) do
      ""
    else
      """
      <path d="M #{x1} #{y1} A #{r} #{r} 0 0 1 #{x2} #{y2}" stroke="black" stroke-width="1" fill="none"/>
      """
    end
  end

  defp label_cell(cell, label_x, label_y) do
    """
    <text x="#{label_x}" y="#{label_y}" font-family="Arial" font-size="10" text-anchor="middle" alignment-baseline="middle">#{cell.row},#{cell.col}</text>
    """
  end

  defp cell_coordinates_with_inset(x, y, cell_size, inset) do
    x1 = x
    x4 = x + cell_size
    x2 = x1 + inset
    x3 = x4 - inset

    y1 = y
    y4 = y + cell_size
    y2 = y1 + inset
    y3 = y4 - inset
    {x1, x2, x3, x4, y1, y2, y3, y4}
  end

  def linked?(grid, cell, dir_fn) do
    Map.get(grid.links, {cell, dir_fn.(grid, cell)})
  end

  def horizontal_passage?(grid, cell) do
    linked?(grid, cell, &east/2) &&
      linked?(grid, cell, &west/2) &&
      !linked?(grid, cell, &north/2) &&
      !linked?(grid, cell, &south/2)
  end

  def vertical_passage?(grid, cell) do
    linked?(grid, cell, &north/2) &&
      linked?(grid, cell, &south/2) &&
      !linked?(grid, cell, &east/2) &&
      !linked?(grid, cell, &west/2)
  end

  def can_tunnel_north?(grid, cell) do
    northern_cell = north(grid, cell)
    northern_cell && north(grid, northern_cell) && horizontal_passage?(grid, northern_cell)
  end

  def can_tunnel_south?(grid, cell) do
    southern_cell = south(grid, cell)
    southern_cell && south(grid, southern_cell) && horizontal_passage?(grid, southern_cell)
  end

  def can_tunnel_east?(grid, cell) do
    eastern_cell = east(grid, cell)
    eastern_cell && east(grid, eastern_cell) && vertical_passage?(grid, eastern_cell)
  end

  def can_tunnel_west?(grid, cell) do
    western_cell = west(grid, cell)
    western_cell && west(grid, western_cell) && vertical_passage?(grid, western_cell)
  end

  def svg(grid, cell_size \\ 10, inset \\ 0, file_name \\ "maze.svg")

  def svg(%Grid{type: :polar} = grid, cell_size, _inset, file_name) do
    width = grid.rows * cell_size * 2
    height = width

    polar_lines =
      for {{row, col}, cell} <- grid.grid do
        theta = 2 * :math.pi() / polar_col_count(grid, row)
        r1 = row * cell_size
        r2 = (row + 1) * cell_size

        x1 = r1 * :math.cos(theta * col) + width / 2 + 1
        y1 = r1 * :math.sin(theta * col) + height / 2 + 1

        x2 = r2 * :math.cos(theta * col) + width / 2 + 1
        y2 = r2 * :math.sin(theta * col) + height / 2 + 1

        x3 = r1 * :math.cos(theta * (col + 1)) + width / 2 + 1
        y3 = r1 * :math.sin(theta * (col + 1)) + height / 2 + 1

        x4 = r2 * :math.cos(theta * (col + 1)) + width / 2 + 1
        y4 = r2 * :math.sin(theta * (col + 1)) + height / 2 + 1

        label_x = ((r2 - r1) / 2 + r1) * :math.cos(theta * (col + 0.5)) + width / 2 + 1
        label_y = ((r2 - r1) / 2 + r1) * :math.sin(theta * (col + 0.5)) + height / 2 + 1

        [
          label_cell(cell, label_x, label_y),
          draw_straight_wall(
            grid,
            cell,
            x1,
            y1,
            x2,
            y2,
            &clockwise/2
          ),
          draw_straight_wall(
            grid,
            cell,
            x3,
            y3,
            x4,
            y4,
            &counter_clockwise/2
          ),
          draw_arc_wall(
            grid,
            cell,
            x1,
            y1,
            r1,
            x3,
            y3,
            &inward/2
          )
        ]
      end

    svg_str = """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width + 2}" height="#{height + 2}">
      <circle cx="#{width / 2 + 1}" cy="#{height / 2 + 1}" r="#{width / 2}" stroke="black" fill="none"/>
      #{List.flatten(polar_lines) |> Enum.uniq() |> Enum.join("\n")}
    </svg>
    """

    File.write!(file_name, svg_str)

    svg_str
  end

  def svg(grid, cell_size, inset, file_name) do
    over_cells =
      for {{row, col}, cell} <- grid.grid do
        if inset == 0 do
          x1 = col * cell_size
          y1 = row * cell_size
          x2 = (col + 1) * cell_size
          y2 = (row + 1) * cell_size

          [
            draw_straight_wall(grid, cell, x1, y1, x2, y1, &north/2),
            draw_straight_wall(grid, cell, x2, y1, x2, y2, &east/2),
            draw_straight_wall(grid, cell, x1, y2, x2, y2, &south/2),
            draw_straight_wall(grid, cell, x1, y1, x1, y2, &west/2)
          ]
        else
          {x1, x2, x3, x4, y1, y2, y3, y4} =
            cell_coordinates_with_inset(col * cell_size, row * cell_size, cell_size, inset)

          [
            if linked?(grid, cell, &north/2) || linked?(grid, cell, &north_under/2) do
              Enum.join([draw_straight_wall(x2, y1, x2, y2), draw_straight_wall(x3, y1, x3, y2)])
            else
              # draw_straight_wall(x2, y2, x3, y3) # gives a 3d effect
              draw_straight_wall(x2, y2, x3, y2)
            end,
            if linked?(grid, cell, &south/2) || linked?(grid, cell, &south_under/2) do
              Enum.join([
                draw_straight_wall(x2, y3, x2, y4),
                draw_straight_wall(x3, y3, x3, y4)
              ])
            else
              draw_straight_wall(x2, y3, x3, y3)
            end,
            if linked?(grid, cell, &west/2) || linked?(grid, cell, &west_under/2) do
              Enum.join([
                draw_straight_wall(x1, y2, x2, y2),
                draw_straight_wall(x1, y3, x2, y3)
              ])
            else
              draw_straight_wall(x2, y2, x2, y3)
            end,
            if linked?(grid, cell, &east/2) || linked?(grid, cell, &east_under/2) do
              Enum.join([
                draw_straight_wall(x3, y2, x4, y2),
                draw_straight_wall(x3, y3, x4, y3)
              ])
            else
              draw_straight_wall(x3, y2, x3, y3)
            end
          ]
        end
      end

    under_cells =
      for {{row, col}, cell} <- grid.under_cells do
        {x1, x2, x3, x4, y1, y2, y3, y4} =
          cell_coordinates_with_inset(col * cell_size, row * cell_size, cell_size, inset)

        if vertical_passage?(grid, cell) do
          [
            draw_straight_wall(x2, y1, x2, y2),
            draw_straight_wall(x3, y1, x3, y2),
            draw_straight_wall(x2, y3, x2, y4),
            draw_straight_wall(x3, y3, x3, y4)
          ]
        else
          [
            draw_straight_wall(x1, y2, x2, y2),
            draw_straight_wall(x1, y3, x2, y3),
            draw_straight_wall(x3, y2, x4, y2),
            draw_straight_wall(x3, y3, x4, y3)
          ]
        end
      end

    width = grid.rows * cell_size
    height = grid.cols * cell_size

    svg_str = """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}">
      #{List.flatten(over_cells ++ under_cells) |> Enum.uniq() |> Enum.join("\n")}
    </svg>
    """

    File.write!(file_name, svg_str)
    svg_str
  end
end
